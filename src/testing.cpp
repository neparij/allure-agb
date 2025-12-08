#include "testing.h"

namespace testing {
    int test_status = 0;
    int passed_tests = 0;
    int failed_tests = 0;

    void init() {
        bn::assert::set_callback(fail);
    }

    bn::string_view &set_suite(const bn::string_view &name) {
        allure::start_suite(name);
        current_suite = name;
        BN_LOG("Running suite '", current_suite, "'...");
        return current_suite;
    }

    bn::string_view & set_case(const bn::string_view &name)  {
        allure::test_start(name);
        test_status = 0;
        current_case = name;
        BN_LOG(" Running case '", current_case, "'...");
        return current_case;
    }

    void unset_suite() {
        allure::end_suite();
        current_suite = "";
    }

    void unset_case() {
        current_case = "";
    }

    void pass() {
        test_status = 0;
        allure::test_pass();
        passed_tests++;
        BN_LOG("✅ Test passed: ", current_suite, " - ", current_case);
    }

    void fail() {
        test_status = 1;
        allure::test_fail();
        failed_tests++;
        BN_LOG('\a', "❌ Test failed: ", current_suite, " - ", current_case);
    }

    void finalize_testcase() {
        if (test_status == 0) {
            pass();
        } else {
            fail();
        }
    }
}
