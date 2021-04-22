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

macro(process_contribution contribution_list)
  # Create handles to reference contrib libraries
  set(local-ns3-contrib-libs)
  foreach(libname ${contribution_list})
    list(APPEND lib${libname} ns${NS3_VER}-contrib-${libname}-${build_type})
    set(lib${libname}-obj ns${NS3_VER}-contrib-${libname}-${build_type}-obj)
  endforeach()

  # Add contribution folders to be built
  foreach(contribname ${contribution_list})
    message(STATUS "Processing contrib/${contribname}")
    add_subdirectory("contrib/${contribname}")
  endforeach()
endmacro()

macro(
  build_contrib_example
  name
  contrib
  source_files
  header_files
  libraries_to_link
  files_to_copy
)
  build_lib_example_impl(
    "contrib/${name}" "${name}" "${source_files}" "${header_files}" "${libraries_to_link}" "${files_to_copy}"
  )
endmacro()

macro(build_contrib_lib name source_files header_files libraries_to_link test_sources)
  build_lib_impl(
    "contrib/${name}" "${name}" "${source_files}" "${header_files}" "${libraries_to_link}" "${test_sources}"
  )
endmacro()
