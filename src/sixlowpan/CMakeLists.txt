
set(name sixlowpan)

# Test will obviously fail due to waf dependency, disabling to prevent runner from caching ccache files
#if (${NS3_EXAMPLES})
#    set(examples_as_test_test_sources
#        test/sixlowpan-examples-test-suite.cc # example-ping-lr-wpan will fail as it relies on Waf
#            )
#endif()

set(source_files
        model/sixlowpan-net-device.cc
        model/sixlowpan-header.cc
        helper/sixlowpan-helper.cc
        )

set(header_files
        model/sixlowpan-net-device.h
        model/sixlowpan-header.h
        helper/sixlowpan-helper.h
        )

set(libraries_to_link ${libinternet} ${libinternet} ${libcore})

set(test_sources
        test/mock-net-device.cc
        test/sixlowpan-hc1-test.cc
        test/sixlowpan-iphc-test.cc
        test/sixlowpan-iphc-stateful-test.cc
        test/sixlowpan-fragmentation-test.cc
        ${examples_as_test_test_sources}
        )

build_lib("${name}" "${source_files}" "${header_files}" "${libraries_to_link}" "${test_sources}")


