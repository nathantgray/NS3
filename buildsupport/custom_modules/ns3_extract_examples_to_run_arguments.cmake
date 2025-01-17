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

macro(exemples_to_run_extract_arguments return_value)
  set(example_list)
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/examples-to-run.py")
    file(STRINGS examples-to-run.py file_contents REGEX "(.*[\\n|\\f|\\n\\f])")
  endif()
  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../test/examples-to-run.py")
    file(STRINGS ../test/examples-to-run.py file_contents REGEX "(.*[\\n|\\f|\\n\\f])")
  endif()

  set(cpp_examples_block -1)
  set(end_cpp_block -1)
  foreach(line ${file_contents})
    string(FIND "${line}" "(\"" cpp_examples)

    if(${cpp_examples} GREATER -1)
      set(cpp_examples_block 1)
    endif()

    if(${cpp_examples_block})
      set(end_cpp_block -1)
      string(FIND "${line}" "python_examples" end_cpp_block)
      if(${end_cpp_block} GREATER -1)
        break()
      endif()

      string(FIND "${line}" "(\"" entry)
      if(${entry} GREATER -1)
        # Extract example arguments \("([^"]*)" # regex pattern
        string(REGEX MATCH "\\\(\"([^\"]*)" trash ${line})
        set(example_arguments ${CMAKE_MATCH_1})

        # Extract "to run" parameter
        string(REGEX MATCH ".*,(.*),.*," trash ${line})
        string(TOUPPER ${CMAKE_MATCH_1} to_run)
        if(${to_run} MATCHES "TRUE")
          list(APPEND example_list "${example_arguments}")
        endif()
      endif()
    endif()
  endforeach()
  set(${return_value} ${example_list})
endmacro()

macro(examples_to_run_find_examples example_name examples_to_run_list matching_examples)
  set(examples)
  foreach(example ${examples_to_run_list})
    string(FIND "${example}" "${example_name}" found)
    # message(WARNING "${found} ${example} ${example_name}")
    if(found GREATER -1)
      list(APPEND examples "${example}")
    endif()
  endforeach()
  set(${matching_examples} "${examples}")
endmacro()
