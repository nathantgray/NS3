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

function(create_test test_name test_id test_arguments working_directory)
  # test.py assume the binary is executed inside the ns-3-dev folder, or ${PROJECT_SOURCE_DIR} in CMake land
  if(WIN32)
    # Windows require this workaround to make sure the DLL files are located
    add_test(
      NAME ctest-${test_name}-${test_id}
      COMMAND
        ${CMAKE_COMMAND} -E env "PATH=$ENV{PATH};${CMAKE_RUNTIME_OUTPUT_DIRECTORY};${CMAKE_LIBRARY_OUTPUT_DIRECTORY}"
        ${test_name} ${test_arguments}
      WORKING_DIRECTORY ${working_directory}
    )
  else()
    add_test(
      NAME ctest-${test_name}-${test_id}
      COMMAND ${test_name} ${test_arguments}
      WORKING_DIRECTORY ${working_directory}
    )
  endif()
endfunction(create_test)

function(process_tests ignore_example test_name examples_list output_directory)
  if(ignore_example)

  else()
    if(NOT examples_list)
      create_test(${test_name} 0 "" ${output_directory})
    else()
      # If arguments for the examples were defined, create a case for each set of parameters
      set(num_examples 0)
      foreach(example ${examples_list})
        # Turn string into list of parameters and remove program name to replace with absolute path
        string(REPLACE " " ";" example ${example})
        list(REMOVE_AT example 0)
        create_test("${test_name}" "${num_examples}" "${example}" "${output_directory}")
        math(EXPR num_examples "${num_examples}+1")
      endforeach()
    endif()
  endif()
endfunction(process_tests)
