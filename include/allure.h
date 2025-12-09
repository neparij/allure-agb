#ifndef GBA_TESTING_SUITE_ALLURE_H
#define GBA_TESTING_SUITE_ALLURE_H
#include <cstdint>

#include "bn_string_view.h"

#define ALLURE_ENABLE_REGISTER 0x4FFF800
#define ALLURE_CONTROL_REGISTER 0x4FFF802

namespace testing::allure {
    typedef uint8_t command_t;
    constexpr command_t COMMAND_NONE = 0x00;
    constexpr command_t COMMAND_START_SUITE = 0x01;
    constexpr command_t COMMAND_END_SUITE = 0x02;
    constexpr command_t COMMAND_TEST_START = 0x03;
    constexpr command_t COMMAND_TEST_PASS = 0x04;
    constexpr command_t COMMAND_TEST_FAIL = 0x05;
    constexpr command_t COMMAND_STEP = 0x06;
    constexpr command_t COMMAND_LOG = 0x07;
    constexpr command_t COMMAND_EXIT = 0xFF;

    struct transport_proto_t {
        char magic[16] = {'A', 'L', 'L', 'U', 'R', 'E', 'R', 'E', 'P', 'O', 'R', 'T', '+', '3', 0, 0};
        command_t command;
        void *src;
        uint32_t src_size;

        transport_proto_t() : command(COMMAND_NONE),
                              src(nullptr),
                              src_size(0) {
        }
    };

    static transport_proto_t allure_transport_instance;

    void init();

    void push_command(command_t command);

    void start_suite(const bn::string_view &suite_name);

    void end_suite();

    void test_start(const bn::string_view &test_name);

    void test_pass();

    void test_fail();

    void step(const bn::string_view &step_name);

    void log(const bn::string_view &log_message);

    void close();
}
#endif //GBA_TESTING_SUITE_ALLURE_H
