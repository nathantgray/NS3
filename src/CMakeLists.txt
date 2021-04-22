# Copyright (c) 2017-2021 Universidade de Brasília
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
# License version 2 as published by the Free Software Foundation;
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not, write to the Free
# Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Author: Gabriel Ferreira <gabrielcarvfer@gmail.com>

# Process subdirectories
foreach(libname ${libs_to_build})
  message(STATUS "Processing src/${libname}")
  add_subdirectory(${libname})
endforeach()

# Build the lib-ns3-static (ns3.x-static-buildtype.a/.lib) with all sublibraries
if(${NS3_STATIC})
  add_library(${lib-ns3-static} STATIC ${PROJECT_SOURCE_DIR}/buildsupport/empty_main.cc "${lib-ns3-static-objs}")
  get_property(local-ns3-external-libs GLOBAL PROPERTY ns3-external-libs)
  target_link_libraries(
    ${lib-ns3-static}
    -static
    -static-libstdc++
    -static-libgcc
    ${LIB_AS_NEEDED_PRE_STATIC}
    ${local-ns3-external-libs}
    ${LIB_AS_NEEDED_POST_STATIC}
  )
endif()

if(${NS3_PYTHON})
  add_library(${ns3-python-bindings} SHARED ${ns3-python-bindings-modules})
  target_link_libraries(
    ${ns3-python-bindings} ${LIB_AS_NEEDED_PRE} ${ns3-libs} ${Python2_LIBRARIES} ${LIB_AS_NEEDED_POST}
  )
endif()
