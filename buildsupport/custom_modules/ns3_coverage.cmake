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

if(${NS3_COVERAGE})
  find_program(GCOVp gcov)
  if(GCOVp)
    add_definitions(--coverage)
    link_libraries(-lgcov)
  endif()
  find_program(LCOVp lcov)
  if(NOT LCOVp)
    message(FATAL_ERROR "LCOV is required but it is not installed.")
  endif()

  # Create a custom target to run test.py --nowaf .gcno and .gcda code coverage output will be in ${CMAKE_BINARY_DIR}
  # a.k.a. cmake_cache/cmake-build-${build_suffix}
  add_custom_target(
    run_test_py
    COMMAND python3 test.py --nowaf
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
  )

  # Create output directory for coverage info and html
  file(MAKE_DIRECTORY ${CMAKE_OUTPUT_DIRECTORY}/coverage)

  # Extract code coverage results and build html report
  add_custom_target(
    coverage_gcc
    COMMAND lcov -o ns3.info -c --directory ${CMAKE_BINARY_DIR}
    COMMAND genhtml ns3.info
    WORKING_DIRECTORY ${CMAKE_OUTPUT_DIRECTORY}/coverage
    DEPENDS run_test_py
  )
endif()
