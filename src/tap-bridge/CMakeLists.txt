if (${NS3_TAP})
    set(name tap-bridge)

    set(source_files
            model/tap-bridge.cc
            model/tap-encode-decode.cc
            helper/tap-bridge-helper.cc
            )

    set(header_files
            model/tap-bridge.h
            model/tap-encode-decode.h
            helper/tap-bridge-helper.h
            )

    set(libraries_to_link ${libcore} ${libinternet} ${libnetwork} )

    set(test_sources
            )


    build_lib("${name}" "${source_files}" "${header_files}" "${libraries_to_link}" "${test_sources}")

    if (WIN32)
        set(tap_creator tap-creator.exe)
    else()
        set(tap_creator tap-creator)
    endif()

    add_definitions(-DTAP_CREATOR="${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/src/tap-bridge/${tap_creator}")


    add_executable(tap-creator
            model/tap-creator.cc
            model/tap-encode-decode.cc
            )

    set_target_properties(tap-creator
            PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/src/tap-bridge/
            )
endif()