#include "allure.h"

#include "testing.h"

namespace testing::allure {
    void init() {
        testing::init();

        allure_transport_instance = transport_proto_t();
        volatile uint16_t &allure_enable_register = *reinterpret_cast<uint16_t *>(ALLURE_ENABLE_REGISTER);
        allure_enable_register = 0x0080;
        __asm volatile("nop");
    }

    void push_command(const command_t command) {
        allure_transport_instance.command = command;
        volatile uint8_t &allure_control_register = *reinterpret_cast<uint8_t *>(ALLURE_CONTROL_REGISTER);
        allure_control_register = 0xFF;
        __asm volatile("nop");
    }

    void start_suite(const bn::string_view &suite_name) {
        allure_transport_instance.src = const_cast<char *>(suite_name.data());
        allure_transport_instance.src_size = suite_name.size();
        push_command(COMMAND_START_SUITE);
    }

    void end_suite() {
        push_command(COMMAND_END_SUITE);
    }

    void test_start(const bn::string_view &test_name) {
        allure_transport_instance.src = const_cast<char *>(test_name.data());
        allure_transport_instance.src_size = test_name.size();
        push_command(COMMAND_TEST_START);
    }

    void test_pass() {
        push_command(COMMAND_TEST_PASS);
    }

    void test_fail() {
        push_command(COMMAND_TEST_FAIL);
    }

    void step(const bn::string_view &step_name) {
        allure_transport_instance.src = const_cast<char *>(step_name.data());
        allure_transport_instance.src_size = step_name.size();
        push_command(COMMAND_STEP);
    }

    void log(const bn::string_view &log_message) {
        allure_transport_instance.src = const_cast<char *>(log_message.data());
        allure_transport_instance.src_size = log_message.size();
        push_command(COMMAND_LOG);
    }

    void close() {
        push_command(COMMAND_EXIT);
        // TODO: More graceful shutdown of the allure transport and mGBA allure listener.
        // volatile uint16_t &allure_enable_register = *reinterpret_cast<uint16_t *>(0x4FFF800);
        // allure_enable_register = 0x0000;
        // __asm volatile("nop");
    }
}
