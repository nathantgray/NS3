file(GLOB_RECURSE scratches ${CMAKE_CURRENT_SOURCE_DIR}/*.cc)

set(DONT_BUILD)

get_property(local-ns3-libs GLOBAL PROPERTY ns3-libs)

foreach(scratch_src ${scratches})
  get_filename_component(scratch_name ${scratch_src} NAME)
  string(REGEX REPLACE "\\.[^.]*$" "" scratch_name ${scratch_name})

  string(FIND "${DONT_BUILD}" "${scratch_name}" res)
  if(res LESS 0)
    add_executable(${scratch_name} "${scratch_src}")
    if(${NS3_STATIC})
      target_link_libraries(${scratch_name} ${LIB_AS_NEEDED_PRE_STATIC} ${lib-ns3-static})
    else()
      target_link_libraries(${scratch_name} "${local-ns3-libs}" "${ns3-contrib-libs}")
    endif()
    set_runtime_outputdirectory(${scratch_name} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/scratch/)
  endif()
endforeach()
