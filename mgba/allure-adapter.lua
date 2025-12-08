-- ===============================
--  Allure Adapter for mGBA
-- ===============================
local json = require(script.dir .. "/dependencies/dkjson")

-- local ALLURE_RESULTS_DIR = script.dir .. "/../../../allure-results"
local ALLURE_RESULTS_DIR = "allure-results"
local ALLURE_TRANSPORT_PROTO_MAGIC = "ALLUREREPORT+3\0\0"
local ALLURE_ENABLE_REGISTER = 0x4FFF800
local ALLURE_CONTROL_REGISTER = 0x4FFF802
local ALLURE_CMD_NONE = 0x00
local ALLURE_CMD_START_SUITE = 0x01
local ALLURE_CMD_END_SUITE = 0x02
local ALLURE_CMD_TEST_START = 0x03
local ALLURE_CMD_TEST_PASS = 0x04
local ALLURE_CMD_TEST_FAIL = 0x05
local ALLURE_CMD_STEP = 0x06
local ALLURE_CMD_LOG = 0x07
local ALLURE_CMD_EXIT = 0xFF

local state = {
    transport = nil,
    transport_watchdog_id = -1,
    current_suite = nil,
    current_test = nil,
    suites = {},
    shutdown = false,
}

local function find_allure_report_magic(region)
    local size = region:size()
    for addr = 0, size - #ALLURE_TRANSPORT_PROTO_MAGIC do
        local bytes = region:readRange(addr, #ALLURE_TRANSPORT_PROTO_MAGIC)
        if bytes == ALLURE_TRANSPORT_PROTO_MAGIC then
            return {
                abs = region:bound() + addr,
                region = region,
                offset = addr,
            }
        end
    end
    return nil
end

-- Read uint8_t variable
local function r8(off)
    return state.transport.region:read8(state.transport.offset + off)
end

-- Read uint16_t variable
local function r32(off)
    return state.transport.region:read32(state.transport.offset + off)
end

-- Read uint32_t variable
local function r16(off)
    return state.transport.region:read16(state.transport.offset + off)
end

-- Read char[256] variable as string
local function rstr(off)
    local bytes = state.transport.region:readRange(state.transport.offset + off, 256)
    local str = ""
    for i = 1, #bytes do
        local b = bytes:byte(i)
        if b == 0 then break end
        str = str .. string.char(b)
    end
    return str
end

-- Create directory if it does not exist
local function ensure_dir(path)
    console:log("Ensuring directory exists: " .. path)
    local results_lock = io.open(path .. "/.ensure.lock", "w")
    if results_lock then
        results_lock:close()
        os.remove(path .. "/.ensure.lock")
        console:log("Directory exists or created: " .. path)
        return true
    else
        local ok, err = os.execute('mkdir "' .. path .. '"')
        if ok then
            console:log("Directory created: " .. path)
            return true
        else
            console:error("Error creating directory: " .. tostring(err))
            return false
        end
    end
end

local function sleep (a)
    local sec = tonumber(os.clock() + a);
    while (os.clock() < sec) do
    end
end

local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

local function current_timestamp()
    return os.time() * 1000
end

local function write_json(filename, obj)
    local f = io.open(filename, "w")
    if f then
        f:write(json.encode(obj, { indent = true }))
        f:close()
    end
end




-- --------------------------
--  События адаптера
-- --------------------------

function start_suite(name)
    local suite_uuid = uuid()
    state.current_suite = {
        uuid = suite_uuid,
        name = name,
        start = current_timestamp(),
        children = {},
        tests = {},
    }
    console:log("Allure Start Suite: " .. name)
end

function end_suite()
    if not state.current_suite then return end
    state.current_suite.stop = current_timestamp()

    -- Контейнер JSON
    local container = {
        uuid = state.current_suite.uuid,
        name = state.current_suite.name,
        children = state.current_suite.children,
        start = state.current_suite.start,
        stop = state.current_suite.stop,
        befores = {},
        afters = {},
    }

    local filename = string.format("%s/%s-container.json", ALLURE_RESULTS_DIR, container.uuid)
    write_json(filename, container)
    console:log("Allure End Suite: " .. state.current_suite.name)
    state.current_suite = nil
end

function test_start(name)
    if not state.current_suite then return end
    local test_uuid = uuid()
    state.current_test = {
        uuid = test_uuid,
        name = name,
        fullName = state.current_suite.name .. "." .. name,
        start = current_timestamp(),
        steps = {},
        status = nil,
        labels = {}
    }
    if state.current_suite then
        -- Apeend Suite to labels
        state.current_test.labels[#state.current_test.labels + 1] = {
            name = "suite",
            value = state.current_suite.name,
        }
    end
    table.insert(state.current_suite.children, test_uuid)
    console:log("Allure Test Start: " .. name)
end

function test_pass()
    if not state.current_test then return end
    step_end("passed")
    state.current_test.status = "passed"
    state.current_test.stop = current_timestamp()

    local filename = string.format("%s/%s-result.json", ALLURE_RESULTS_DIR, state.current_test.uuid)
    write_json(filename, state.current_test)
    console:log("Allure Test Pass: " .. state.current_test.name)
    state.current_test = nil
end

function test_fail()
    if not state.current_test then return end
    step_end("failed")
    state.current_test.status = "failed"
    state.current_test.stop = current_timestamp()

    local filename = string.format("%s/%s-result.json", ALLURE_RESULTS_DIR, state.current_test.uuid)
    write_json(filename, state.current_test)
    console:log("Allure Test Fail: " .. state.current_test.name)
    state.current_test = nil
end

function test_broken()
    if not state.current_test then return end
    state.current_test.status = "broken"
    state.current_test.stop = current_timestamp()

    local filename = string.format("%s/%s-result.json", ALLURE_RESULTS_DIR, state.current_test.uuid)
    write_json(filename, state.current_test)
    console:log("Allure Test Broken: " .. state.current_test.name)
    state.current_test = nil
end

function step(name)
    if not state.current_test then return end
    table.insert(state.current_test.steps, {
        name = name,
        start = current_timestamp(),
    })
    console:log("Allure Step: " .. name)
end

function step_end(status)
    if not state.current_test then return end
    local steps = state.current_test.steps
    if #steps == 0 then return end
    local step = steps[#steps]
    if not step.stop then
        step.stop = current_timestamp()
    end
    if not step.status then
        step.status = status or "passed"
    end
end

function log(msg)
    if not state.current_test then return end
    table.insert(state.current_test.steps, {
        name = msg,
        start = current_timestamp(),
        stop = current_timestamp(),
        status = "passed",
    })
    console:log("Allure Log: " .. msg)
end






local ALLURE_RESULTS_DIRectory_ok = ensure_dir(ALLURE_RESULTS_DIR)

if not ALLURE_RESULTS_DIRectory_ok then
    console:error("Allure Adapter: Cannot proceed without results directory.")
    return
end


local function allure_state_clear()
    state.transport = nil
--     if state.transport_watchdog_id ~= -1 then
--         emu:clearBreakpoint(state.transport_watchdog_id)
--         state.transport_watchdog_id = -1
--     end
    state.current_suite = nil
    state.current_test = nil
    state.suites = {}
    console:log("Allure Adapter: State cleared.")
end


local function allure_transport_watchdog_callback()
    local cmd = r8(0x10)
    local src = r32(0x14)
    local src_size = r32(0x18)
    if cmd == ALLURE_CMD_NONE then
        console:warn("Allure Adapter: Received ALLURE_CMD_NONE, ignoring.")
    elseif cmd == ALLURE_CMD_START_SUITE then
        start_suite(emu:readRange(src, src_size))
    elseif cmd == ALLURE_CMD_END_SUITE then
        end_suite()
    elseif cmd == ALLURE_CMD_TEST_START then
        test_start(emu:readRange(src, src_size))
    elseif cmd == ALLURE_CMD_TEST_PASS then
        test_pass()
    elseif cmd == ALLURE_CMD_TEST_FAIL then
        test_fail()
    elseif cmd == ALLURE_CMD_STEP then
        step_end("passed")
        step(emu:readRange(src, src_size))
    elseif cmd == ALLURE_CMD_LOG then
        log(emu:readRange(src, src_size))
    elseif cmd == ALLURE_CMD_EXIT then
        console:log("Allure Adapter: Received EXIT command...")
        local warns = false
        if state.current_test then
            console:warn("Allure Adapter: Test is still running during EXIT, marking as broken.")
            test_broken()
            warns = true
        end
        if state.current_suite then
            console:warn("Allure Adapter: Suite is still running during EXIT, ending suite.")
            end_suite()
            warns = true
        end
        allure_state_clear()

        console:log("Allure Adapter: Exiting mGBA with code " .. (warns and "1" or "0") .. ".")
        sleep(3) -- Wait a bit to ensure all I/O is done and emulator can exit cleanly
        os.exit(warns and 1 or 0)
        return
    else
        console:warn(("Allure Adapter: Unknown command 0x%02X received in transport watchdog."):format(cmd))
    end
end


local function allure_enable_register_watchdog()
    if not state.transport then
        state.transport = find_allure_report_magic(emu.memory.iwram)
        if state.transport then
            console:log(("🌈 allure_report_transport_t found at 0x%08X in %s"):format(state.transport.abs, state.transport.region:name()))
            state.transport_watchdog_id = emu:setWatchpoint(allure_transport_watchdog_callback, ALLURE_CONTROL_REGISTER, C.WATCHPOINT_TYPE.WRITE, -1)
            console:log("Allure Adapter: Transport watchdog set with id " .. tostring(state.transport_watchdog_id))
        else
            console:error("Allure Adapter: Cannot find allure_report_transport_t structure in memory.")
            return
        end
    else
        console:warn("Allure Adapter: Detected write to ALLURE_ENABLE_REGISTER, processing report...")
    end
end

emu:setWatchpoint(allure_enable_register_watchdog, ALLURE_ENABLE_REGISTER, C.WATCHPOINT_TYPE.RW, -1)

callbacks:add("reset", allure_state_clear)
callbacks:add("stop", allure_state_clear)
callbacks:add("shutdown", allure_state_clear)
