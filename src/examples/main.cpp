#include "bn_core.h"
#include "allure.h"
#include "bn_format.h"
#include "suites/example_tests.h"


#include "bn_sprite_text_generator.h"
#include "common_fixed_8x8_sprite_font.h"
#include "common_info.h"

[[noreturn]] int main() {
    bn::core::init();
    testing::allure::init();
    example_tests().run();
    testing::allure::close();

    // Display test results using info screen
    bn::sprite_text_generator text_generator(common::fixed_8x8_sprite_font);
    const bn::string<64> test_passed_text = bn::format<64>("Tests passed: {}", testing::passed_tests);
    const bn::string<64> test_failed_text = bn::format<64>("Tests failed: {}", testing::failed_tests);
    const bn::string<64> total_tests_text = bn::format<64>("Total tests: {}", testing::passed_tests + testing::failed_tests);
    const bn::string_view results_text_lines[6] = {
        test_passed_text,
        test_failed_text,
        total_tests_text,
        "",
        "Use Allure cli to view report.",
        "Check README.md for details."
    };
    common::info info("Allure Report Demo", results_text_lines, text_generator);
    info.set_show_always(true);

    while (true) {
        bn::core::update();
    }
}
