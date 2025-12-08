#ifndef EXAMPLE_TESTS_H
#define EXAMPLE_TESTS_H

#include "suite.h"

class example_tests : public testing::test_suite {
public:
    example_tests() : test_suite("example suite") {
    }

    void run() {
        test_case("check booleans", [this] {
            KS_ASSERT(true == true);
            KS_ASSERT(false == false);
        });

        test_case("check integer", [this] {
            KS_ASSERT(this->foo == 42, "foo should be 42");
        });

        test_case("failing test", [this] {
            KS_ASSERT(true == false, "this test is supposed to fail");
        });
    }

private:
    int foo = 42;
};


#endif //EXAMPLE_TESTS_H
