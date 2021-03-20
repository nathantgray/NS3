function(cache_cmake_flag cmake_flag cache_entry output_string)
    if (${${cmake_flag}})
        set(${output_string} "${${output_string}}${cache_entry} = True\n" PARENT_SCOPE)
    else()
        set(${output_string} "${${output_string}}${cache_entry} = False\n" PARENT_SCOPE)
    endif()
endfunction(cache_cmake_flag)

function(generate_c4che_cachepy)
    # Build _cache.py file consumed by test.py
    set(cache_contents "")

    GET_PROPERTY(local-ns3-libs GLOBAL PROPERTY ns3-libs)
    string(APPEND cache_contents "NS3_ENABLED_MODULES = [")
    foreach (module_library ${local-ns3-libs}) # fetch core module libraries
        string(APPEND cache_contents "'")
        string(REPLACE "-" ";" module_list ${module_library}) # split ns3ver-library-buildmode into a cmake list ns3ver;library;buildmode
        list(LENGTH module_list len)
        MATH(EXPR len "${len}-1")
        list(REMOVE_AT module_list ${len}) # some modules have hyphens, so we pop out the last element of the list
        list(REMOVE_AT module_list 0) # and then pop the first element of the list
        list(JOIN module_list "-" module_name) # then we join the remaining parts back again with hyphen
        string(APPEND cache_contents "ns3-${module_name}',")
    endforeach()
    string(APPEND cache_contents "]\n")

    string(APPEND cache_contents "NS3_ENABLED_CONTRIBUTED_MODULES = [] \n") #missing support

    if(NOT WIN32)
        string(REPLACE ":" "', '" PATH_LIST $ENV{PATH})
    else()
        string(REPLACE ";" "', '" PATHLIST "$ENV{PATH}") # turn CMake list into a single string and replace ; with ,
        set(PATHLIST "'${PATHLIST}'") # add first and last single quote marks
        string(REPLACE "\\" "\\\\" PATHLIST ${PATHLIST}) # replace single backslash \ with double backslash \\
    endif()
    string(APPEND cache_contents "NS3_MODULE_PATH = ['${PATH_LIST}', '${CMAKE_OUTPUT_DIRECTORY}', '${CMAKE_LIBRARY_OUTPUT_DIRECTORY}']\n")

    cache_cmake_flag(NS3_NSC      "NSC_ENABLED"      cache_contents) # missing support
    cache_cmake_flag(NS3_REALTIME "ENABLE_REAL_TIME" cache_contents)
    cache_cmake_flag(NS3_PTHREAD  "ENABLE_THREADING" cache_contents)
    cache_cmake_flag(NS3_EXAMPLES "ENABLE_EXAMPLES"  cache_contents)
    cache_cmake_flag(NS3_TESTS    "ENABLE_TESTS"     cache_contents)
    cache_cmake_flag(NS3_OPENFLOW "ENABLE_OPENFLOW"  cache_contents)

    GET_PROPERTY(local-ns3-example-folders GLOBAL PROPERTY ns3-example-folders)
    string(APPEND cache_contents "EXAMPLE_DIRECTORIES = [")
    foreach (example_folder ${local-ns3-example-folders})
        string(APPEND cache_contents "'${example_folder}',")
    endforeach()
    string(APPEND cache_contents "]\n")

    string(APPEND cache_contents "ENABLE_PYTHON_BINDINGS = False\n") # missing support
    string(APPEND cache_contents "NSCLICK = False \n") # missing support
    string(APPEND cache_contents "ENABLE_BRITE = False\n") # missing support
    string(APPEND cache_contents "APPNAME = 'ns'\n")

    if(${build_type} MATCHES "deb")
        set(build_profile debug)
    elseif(${build_type} MATCHES "rel")
        set(build_profile release)
    else()
        set(build_profile debug)
    endif()
    string(APPEND cache_contents "BUILD_PROFILE = '${build_profile}'\n")
    string(APPEND cache_contents "VERSION = '3-dev' \n")
    string(APPEND cache_contents "PYTHON = ['${Python3_EXECUTABLE}']\n")
    string(APPEND cache_contents "VALGRIND_FOUND = False \n") # missing support

    file(WRITE ${CMAKE_OUTPUT_DIRECTORY}/c4che/_cache.py "${cache_contents}")
endfunction(generate_c4che_cachepy)
