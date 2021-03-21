if (${NS3_COVERAGE})
    find_program(GCOVp gcov)
    if (GCOVp)
        add_definitions(--coverage)
        link_libraries(-lgcov)
    endif()
    find_program(LCOVp lcov)
    if (NOT LCOVp)
        message(FATAL_WARNING "LCOV is required but it is not installed.")
    endif()

    # Create a custom target to run test.py --nowaf
    # .gcno and .gcda code coverage output will be in ${CMAKE_BINARY_DIR} a.k.a. cmake_cache/cmake-build-${build_suffix}
    add_custom_target(run_test_py
            COMMAND python3 test.py --nowaf
            WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})

    # Create output directory for coverage info and html
    file(MAKE_DIRECTORY ${CMAKE_OUTPUT_DIRECTORY}/coverage)

    # Extract code coverage results and build html report
    add_custom_target(coverage_gcc
            COMMAND lcov -o ns3.info -c --directory ${CMAKE_BINARY_DIR}
            COMMAND genhtml ns3.info
            WORKING_DIRECTORY ${CMAKE_OUTPUT_DIRECTORY}/coverage
            DEPENDS run_test_py)
endif()