#ifndef GBA_TESTING_SUITE_TESTING_H
#define GBA_TESTING_SUITE_TESTING_H

#include "allure.h"
#include "butano.h"
#include "bn_assert.h"
#include "bn_log.h"
#include "bn_string_view.h"
#define GBA_TESTING_SUITE_ASSERT_BUFFER_SIZE BN_CFG_ASSERT_BUFFER_SIZE

namespace testing {
    extern int test_status;
    extern int passed_tests;
    extern int failed_tests;
}

#define TEST_ASSERT(condition, ...) \
    do { \
        testing::step(#condition __VA_OPT__(, ) __VA_ARGS__); \
        if(! (condition)) [[unlikely]] { \
            testing::test_status = 1; \
            return; \
        } \
    } while(false)

namespace testing {
    static bn::string_view current_suite = "";
    static bn::string_view current_case = "";

    void init();

    bn::string_view &set_suite(const bn::string_view &name);

    bn::string_view &set_case(const bn::string_view &name);

    void unset_suite();

    void unset_case();

    void pass();

    void fail();

    void finalize_testcase();

    template<typename ... Args>
    void step(const char *condition_msg, const Args &...args) {
        // Stack, not IWRAM BSS: this is only live during a TEST_ASSERT.
        char message_buffer[GBA_TESTING_SUITE_ASSERT_BUFFER_SIZE];
        message_buffer[0] = '\0';
        bn::istring_base istring(message_buffer);
        bn::ostringstream string_stream(istring);
        string_stream.append("  :: ");
        string_stream.append(condition_msg);
        // TODO: Allow for custom step names instead of assert conditions naming.
        // if (sizeof...(args) != 0) {
        //     string_stream.append(" :: ");
        //     string_stream.append_args(args...);
        // }
        allure::step(message_buffer);
        BN_LOG(message_buffer);
    }
}

#endif //GBA_TESTING_SUITE_TESTING_H
