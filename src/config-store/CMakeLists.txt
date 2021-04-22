set(name config-store)

if(${GTK2_FOUND})
  set(GTK2_SOURCE_FILES model/gtk-config-store.cc model/model-node-creator.cc model/model-typeid-creator.cc
                        model/display-functions.cc
  )

  set(GTK2_HEADER_FILES model/gtk-config-store.h)
endif()

if(${LIBXML2_FOUND})
  set(xml2_sources model/xml-config.cc)
  set(xml2_libraries ${LIBXML2_LIBRARIES})
endif()

set(source_files
    ${GTK2_SOURCE_FILES}
    ${xml2_sources}
    model/attribute-iterator.cc
    model/config-store.cc
    model/attribute-default-iterator.cc
    model/file-config.cc
    model/raw-text-config.cc
)

set(header_files ${GTK2_HEADER_FILES} model/file-config.h model/config-store.h)

set(libraries_to_link ${libcore} ${libnetwork} ${GTK2_LIBRARIES} ${xml2_libraries})

set(test_sources)

build_lib("${name}" "${source_files}" "${header_files}" "${libraries_to_link}" "${test_sources}")

if(${LIBXML2_FOUND})
  # Define HAVE_LIBXML2 to make sure conditional compilation works correctly
  target_include_directories(${libconfig-store-obj} PUBLIC ${LIBXML2_INCLUDE_DIR})
endif()
