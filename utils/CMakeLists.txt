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

if(${NS3_TESTS})
  get_property(local-ns3-libs GLOBAL PROPERTY ns3-libs)
  get_property(local-ns3-libs-tests GLOBAL PROPERTY ns3-libs-tests)

  if(WIN32)
    set(libraries_to_link ${local-ns3-libs})
    list(REMOVE_ITEM libraries_to_link ${libtest})

    add_executable(test-runner test-runner.cc ${local-ns3-libs-tests} $<TARGET_OBJECTS:${libtest}>)
    target_link_libraries(test-runner ${LIB_AS_NEEDED_PRE} ${libraries_to_link} ${LIB_AS_NEEDED_POST})
  else()
    add_executable(test-runner test-runner.cc $<TARGET_OBJECTS:${libtest}>)
    target_link_libraries(
      test-runner ${LIB_AS_NEEDED_PRE} ${local-ns3-libs} ${local-ns3-libs-tests} ${LIB_AS_NEEDED_POST}
    )
  endif()
  set_runtime_outputdirectory(test-runner ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/utils/)

  add_executable(bench-simulator bench-simulator.cc)
  target_link_libraries(bench-simulator ${libcore})
  set_runtime_outputdirectory(bench-simulator ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/utils/)

  add_executable(bench-packets bench-packets.cc)
  target_link_libraries(bench-packets ${libnetwork})
  set_runtime_outputdirectory(bench-packets ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/utils/)

  add_executable(print-introspected-doxygen print-introspected-doxygen.cc)
  target_link_libraries(print-introspected-doxygen ${local-ns3-libs})
  set_runtime_outputdirectory(print-introspected-doxygen ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/utils/)

endif()
