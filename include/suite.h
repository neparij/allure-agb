#ifndef GBA_TESTING_SUITE_TESTSUITE_H
#define GBA_TESTING_SUITE_TESTSUITE_H

#include "bn_string_view.h"
#include "testing.h"

namespace testing {
    class test_suite {
    public:
        explicit test_suite(const bn::string_view &name) : _name(set_suite(name)) {
        }

        ~test_suite() {
            unset_suite();
        }

        void run();

        template<typename Func>
        static void test_case(const bn::string_view &name, Func &&func) {
            set_case(name);
            func();
            finalize_testcase();
            unset_case();
        }

    private:
        bn::string_view _name{};
    };
}

#endif //GBA_TESTING_SUITE_TESTSUITE_H
