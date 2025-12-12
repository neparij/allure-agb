#ifndef GBA_TESTING_SUITE_BUTANO_H
#define GBA_TESTING_SUITE_BUTANO_H

#if __has_include("bn_core.h") and __has_include("bn_version.h")
#include "bn_version.h"
#define GBA_TESTING_SUITE_BUTANO_ENABLED
#define GBA_TESTING_SUITE_ASSERT_BUFFER_SIZE BN_CFG_ASSERT_BUFFER_SIZE
#else
    // TODO: Add ability for Butano-less builds
    #undef GBA_TESTING_SUITE_BUTANO_ENABLED
#endif

#endif
