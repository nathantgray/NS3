set(name brite-generic-example)
set(source_files ${name}.cc)
set(header_files)
set(libraries_to_link ${libbrite} ${libinternet} ${libpoint-to-point} ${libnix-vector-routing} ${libapplications})
set(files_to_copy)
build_lib_example("${name}" "${source_files}" "${header_files}" "${libraries_to_link}" "${files_to_copy}")

if(${ENABLE_MPI})
  set(name brite-MPI-example)
  set(source_files ${name}.cc)
  set(header_files)
  set(libraries_to_link ${libbrite} ${libinternet} ${libpoint-to-point} ${libnix-vector-routing} ${libapplications}
                        ${libmpi} ${MPI_CXX_LIBRARIES}
  )
  set(files_to_copy)
  build_lib_example("${name}" "${source_files}" "${header_files}" "${libraries_to_link}" "${files_to_copy}")
  target_include_directories(${name} PUBLIC ${MPI_CXX_INCLUDE_DIRS})
endif()
