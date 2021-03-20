function(generate_buildstatus)
    # Build build-status.py file consumed by test.py
    set(buildstatus_contents "#! /usr/bin/env python3\n\n")
    string(APPEND buildstatus_contents "ns3_runnable_programs = [")

    GET_PROPERTY(local-ns3-executables GLOBAL PROPERTY ns3-execs)
    foreach (executable ${local-ns3-executables})
        string(APPEND buildstatus_contents "'${executable}', ")
    endforeach()
    string(APPEND buildstatus_contents "]\n\n")

    string(APPEND buildstatus_contents "ns3_runnable_scripts = [") # missing support
    string(APPEND buildstatus_contents "]\n\n")

    file(WRITE ${CMAKE_OUTPUT_DIRECTORY}/build-status.py "${buildstatus_contents}")
endfunction(generate_buildstatus)