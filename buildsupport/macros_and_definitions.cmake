#Export compile time variable setting the directory to the NS3 root folder
add_definitions(-DPROJECT_SOURCE_PATH="${PROJECT_SOURCE_DIR}")

# WSLv1 doesn't support tap features
if(EXISTS "/proc/version")
    FILE(READ "/proc/version" CMAKE_LINUX_DISTRO)
    string(FIND ${CMAKE_LINUX_DISTRO} "Microsoft" res)
    if(res EQUAL -1)
        set(WSLv1 False)
    else()
        set(WSLv1 True)
    endif()
endif()

#Set Linux flag if on Linux
if (UNIX AND NOT APPLE)
    set(LINUX TRUE)
    add_definitions(-D__LINUX__)
endif()

if(APPLE)
    add_definitions(-D__APPLE__)
endif()

if (WIN32)
    add_definitions(-D__WIN32__)
endif()

if (MSVC)
    set(MSVC True)
else()
    set(MSVC False)
endif()

if(CMAKE_XCODE_BUILD_SYSTEM)
    set(XCODE True)
else()
    set(XCODE False)
endif()

#Output folders
set(CMAKE_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR}/build)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_OUTPUT_DIRECTORY}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_OUTPUT_DIRECTORY}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_OUTPUT_DIRECTORY})
set(CMAKE_HEADER_OUTPUT_DIRECTORY  ${CMAKE_OUTPUT_DIRECTORY}/ns3)
set(THIRD_PARTY_DIRECTORY ${PROJECT_SOURCE_DIR}/3rd-party)
link_directories(${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
link_directories(${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

#fPIC and fPIE
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

#When using MinGW, you usually don't want to add your MinGW folder to the path to prevent collisions with other programs
if (WIN32 AND NOT ${MSVC})
    #If using MSYS2
    set(MSYS2_PATH "E:\\tools\\msys64\\mingw64")
    set(GTK2_GDKCONFIG_INCLUDE_DIR "${MSYS2_PATH}\\include\\gtk-2.0")
    set(GTK2_GLIBCONFIG_INCLUDE_DIR "${MSYS2_PATH}\\include\\gtk-2.0")
    set(QT_QMAKE_EXECUTABLE "${MSYS2_PATH}\\bin\\qmake.exe")
    set(QT_RCC_EXECUTABLE   "${MSYS2_PATH}\\bin\\rcc.exe")
    set(QT_UIC_EXECUTABLE   "${MSYS2_PATH}\\bin\\uic.exe")
    set(QT_MOC_EXECUTABLE   "${MSYS2_PATH}\\bin\\moc.exe")
    set(QT_MKSPECS_DIR      "${MSYS2_PATH}\\share\\qt4\\mkspecs")
    set(ENV{PATH} "$ENV{PATH};${MSYS2_PATH}\\bin;")          #contains std libraries
    set(ENV{PATH} "$ENV{PATH};${MSYS2_PATH}\\..\\usr\\bin;") #contains unzip required for Vcpkg
    #set(ENV{PATH} "$ENV{PATH}${MSYS2_PATH}\\lib;")
    #set(ENV{PATH} "$ENV{PATH}${CMAKE_LIBRARY_OUTPUT_DIRECTORY};")
    #set(ENV{PATH} "$ENV{PATH}${CMAKE_RUNTIME_OUTPUT_DIRECTORY};")
endif()

if(${MSVC} OR ${XCODE})
    #Is that so hard not to break people's CI, MSFT and AAPL?
    #Why would you output the targets to a Debug/Release subfolder? Why?
    foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
        string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
        set( CMAKE_RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY} )
        set( CMAKE_LIBRARY_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_LIBRARY_OUTPUT_DIRECTORY} )
        set( CMAKE_ARCHIVE_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${CMAKE_ARCHIVE_OUTPUT_DIRECTORY} )
    endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )
endif()


#Include the cmake file that provides a Hunter-like interface to VcPkg
include(buildsupport/vcpkg_hunter.cmake)


#Check the number of threads
include(ProcessorCount)
ProcessorCount(NumThreads)


#Set compiler options and get command to force unused function linkage (useful for libraries)
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(LIB_AS_NEEDED_PRE  )
set(LIB_AS_NEEDED_POST )
if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "GNU" AND NOT APPLE)
    # using GCC
    set(LIB_AS_NEEDED_PRE  -Wl,--no-as-needed)
    set(LIB_AS_NEEDED_POST -Wl,--as-needed   )
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
    set(BUILD_SHARED_LIBS TRUE)
elseif ("${CMAKE_CXX_COMPILER_ID}" MATCHES "MSVC" OR "${CMAKE_CXX_SIMULATE_ID}" MATCHES "MSVC")
    set(CMAKE_CXX_STANDARD 17) # filesystem

    #Check the number of threads
    include(ProcessorCount)
    ProcessorCount(NumThreads)

    # using Visual Studio C++
    set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS TRUE)
    set(BUILD_SHARED_LIBS TRUE)
    set(CMAKE_MSVC_PARALLEL ${NumThreads})

    # Force clang to keep static consts, but can also cause weird linking issues
    # https://reviews.llvm.org/D53457
    #add_definitions(/clang:-fkeep-static-consts)

    # MSVC needs an explicit flag to enable exceptions support
    # https://docs.microsoft.com/en-us/cpp/build/reference/eh-exception-handling-model?redirectedfrom=MSDN&view=vs-2019
    add_definitions(/EHs)

    # Suppress warnings
    #add_definitions(/W0)

    # /Gy forces object functions to be made into a COMDAT(???), preventing removal by the linker
    add_definitions(/Gy)

    # For whatever reason getting M_PI and other math.h definitions from cmath requires this definition
    # https://docs.microsoft.com/en-us/cpp/c-runtime-library/math-constants?view=vs-2019
    add_definitions(/D_USE_MATH_DEFINES)

    # Boring warnings about standard functions being unsecure (as if their version was...)
    add_definitions(/D_CRT_SECURE_NO_WARNINGS)

    # Set RUNNING_ON_VALGRIND to false to make int64x64 test suite happy
    add_definitions(/DRUNNING_ON_VALGRIND=false)

    # Prevent windows.h from defining a ton of additional crap
    add_definitions(/DNOMINMAX /DWIN32_LEAN_AND_MEAN)
endif()

if ("${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang" AND APPLE)
    # using Clang
    #set(LIB_AS_NEEDED_PRE -all_load)
    set(LIB_AS_NEEDED_POST   )
endif()

macro(SUBDIRLIST result curdir)
    file(GLOB children RELATIVE ${curdir} ${curdir}/*)
    set(dirlist "")
    foreach(child ${children})
        if(IS_DIRECTORY ${curdir}/${child})
            LIST(APPEND dirlist ${child})
        endif()
    endforeach()
    set(${result} ${dirlist})
endmacro()

#process all options passed in main cmakeLists
macro(process_options)
    #process debug switch
    #Used in build-profile-test-suite
    string(TOUPPER ${CMAKE_BUILD_TYPE} cmakeBuildType)
    if(${cmakeBuildType} STREQUAL "DEBUG")
        add_definitions(-DNS3_BUILD_PROFILE_DEBUG)
        set(build_type "deb")
    elseif(${cmakeBuildType} STREQUAL "RELWITHDEBINFO")
        add_definitions(-DNS3_BUILD_PROFILE_RELEASE)
        set(build_type "reldeb")
    elseif(${cmakeBuildType} STREQUAL "RELEASE")
        add_definitions(-DNS3_BUILD_PROFILE_OPTIMIZED)
        set(build_type "rel")
    else()
        add_definitions(-DNS3_BUILD_PROFILE_OPTIMIZED)
        set(build_type "minsizerel")
    endif()

    if (${NS3_ENABLE_BUILD_VERSION})
        add_definitions(-DENABLE_BUILD_VERSION=1)

        # Split NS3_VER (ns-3.<minor>[.patch][-RC<digit>]) into:
        string(REPLACE "-" ";" NS3_VER_LIST ${NS3_VER}) #splits into ns;3.<minor>[.patch];RC (len==2 no RC)
        list(LENGTH NS3_VER_LIST NS3_VER_LIST_LEN)

        if(${NS4_VER_LIST_LEN} EQUAL 2)
            set(VERSION_RELEASE_CANDIDATE 0)
        else()
            list(GET NS3_VER_LIST 2 RELEASE_CANDIDATE)
            string(REPLACE "RC" "" RELEASE_CANDIDATE ${RELEASE_CANDIDATE})
            set(VERSION_RELEASE_CANDIDATE ${RELEASE_CANDIDATE})
        endif()

        list(GET NS3_VER_LIST 1 VERSION_STRING)
        string(REPLACE "." ";" VERSION_LIST ${VERSION_STRING})

        list(GET VERSION_LIST 0 VERSION_MAJOR)
        list(GET VERSION_LIST 1 VERSION_MINOR)
        list(GET VERSION_LIST 2 VERSION_PATCH)

        #todo: Fetch git history and extract:
        set(VERSION_TAG )
        set(CLOSEST_TAG )
        set(VERSION_TAG_DISTANCE )
        set(VERSION_COMMIT_HASH )
        set(VERSION_DIRTY_FLAG )

        # Set
        set(BUILD_PROFILE ${cmakeBuildType})
        configure_file(buildsupport/version-defines-template.h ${CMAKE_HEADER_OUTPUT_DIRECTORY}/version-defines.h)
    endif()

    if(${NS3_TESTS})
        enable_testing()
        if (${NS3_EXAMPLES})
            include(buildsupport/custom_modules/ns3_coverage.cmake)
        endif()
    endif()

    find_program(CLANG_TIDY clang-tidy)
    if (CLANG_TIDY AND NOT ${MSVC})
        set(CMAKE_CXX_CLANG_TIDY "clang-tidy;-checks=clang-analyzer-*,bugprone-*,cppcoreguidelines-*,portability-*")
    else()
        message(STATUS "Proceeding without clang-tidy static analysis")
    endif()

    find_program(CLANG_FORMAT clang-format)
    if (CLANG_FORMAT)
        file(GLOB_RECURSE
                ALL_CXX_SOURCE_FILES
                src/*.cc src/*.h
                examples/*.cc examples/*.h
                utils/*.cc utils/*.h
                scratch/*.cc scratch/*.h
                )
        add_custom_target(clang-format
                COMMAND clang-format -style=file -i ${ALL_CXX_SOURCE_FILES}
                )
        unset(ALL_CXX_SOURCE_FILES)
    else()
        message(STATUS "Proceeding without clang-format target")
    endif()

    #Set common include folder (./build, where we find ns3/core-module.h)
    include_directories(${CMAKE_OUTPUT_DIRECTORY})
    #link_directories(${CMAKE_LIBRARY_OUTPUT_DIRECTORY})
    #link_directories(${CMAKE_RUNTIME_OUTPUT_DIRECTORY})

    #Add a hunter-like interface to Vcpkg
    if (${AUTOINSTALL_DEPENDENCIES})
        setup_vcpkg()
        include("${VCPKG_DIR}/scripts/buildsystems/vcpkg.cmake")
    endif()

    #Copy all header files to outputfolder/include/
    file(GLOB_RECURSE include_files ${PROJECT_SOURCE_DIR}/src/*.h) #just copying every single header into ns3 include folder
    file(COPY ${include_files} DESTINATION ${CMAKE_HEADER_OUTPUT_DIRECTORY})

    #Process Brite 3rd-party submodule and dependencies
    if(${NS3_BRITE})
        if(WIN32 OR APPLE)
            set(${NS3_BRITE} OFF)
            message(WARNING "Not building Brite on Windows/Mac")
        else()
            list(APPEND 3rd_party_libraries_to_build brite)
        endif()
    endif()

    if(${NS3_CLICK})
        if(WIN32 OR APPLE)
            set(${NS3_CLICK} OFF)
            message(WARNING "Not building Click on Windows/Mac")
        else()
            list(APPEND 3rd_party_libraries_to_build click)
        endif()
    endif()


    
    #Process Openflow 3rd-party submodule and dependencies
    if(${NS3_OPENFLOW})
        if(WIN32)
            set(${NS3_OPENFLOW} OFF)
            message(WARNING "Not building Openflow on Windows")
        else()
            list(APPEND 3rd_party_libraries_to_build openflow)
        endif()
    endif()

    #Process ns3 Openflow module and dependencies
    set(OPENFLOW_REQUIRED_BOOST_LIBRARIES)

    if(${NS3_LIBXML2} OR ${NS3_OPENFLOW})
        #LibXml2
        find_package(LibXml2)
        if(NOT ${LIBXML2_FOUND})
            if (${AUTOINSTALL_DEPENDENCIES})
                #If we don't find installed, install
                add_package (libxml2)
                find_package(LibXml2)
            endif()
        endif()
        find_package(LibXml2)
        if(NOT ${LIBXML2_FOUND})
            message(WARNING "LibXML2 was not found. Continuing without it.")
        else()
            link_directories(${LIBXML2_LIBRARY_DIRS})
            include_directories(${LIBXML2_INCLUDE_DIR})
            #add_definitions(${LIBXML2_DEFINITIONS})
        endif()
    endif()


    if(${NS3_BOOST})
        #find_package(Boost)
        #if(NOT ${BOOST_FOUND})
        if (NOT ${AUTOINSTALL_DEPENDENCIES})
            message(FATAL_ERROR "BoostC++ ${NOT_FOUND_MSG}")
        else()
            #add_package(boost) #this will install all the boost libraries and was a bad idea

            set(requiredBoostLibraries
                    ${OPENFLOW_REQUIRED_BOOST_LIBRARIES}
                    )

            #Holds libraries to link later
            set(BOOST_LIBRARIES
                    )
            set(BOOST_INCLUDES
                    )

            #For each of the required boost libraries
            foreach(requiredBoostLibrary ${requiredBoostLibraries})
                set(boostLib boost-${requiredBoostLibrary})
                add_package(${boostLib})
                get_property(${boostLib}_dir GLOBAL PROPERTY DIR_${boostLib})
                #include_directories(${boostLib}/include) #damned Boost-assert undefines assert, causing all sorts of problems with Brite
                list(APPEND BOOST_INCLUDES ${${boostLib}_dir}/include) #add BOOST_INCLUDES per target to avoid collisions

                #Some boost libraries (e.g. static-assert) don't have an associated library
                if (EXISTS ${${boostLib}_dir}/lib)
                    link_directories(${${boostLib}_dir}/lib)

                    if (WIN32)
                        list(APPEND BOOST_LIBRARIES libboost_${requiredBoostLibrary})
                    else()
                        list(APPEND BOOST_LIBRARIES libboost_${requiredBoostLibrary}.a)
                    endif()
                endif()
            endforeach()


            set(BOOST_FOUND TRUE)
        endif()
        #else()
        #    link_directories(${BOOST_LIBRARY_DIRS})
        #    include_directories( ${BOOST_INCLUDE_DIR})
        #endif()
    endif()



    #PyTorch still need some fixes on Windows
    if(WIN32 AND ${NS3_PYTORCH})
        message(WARNING "Libtorch linkage on Windows still requires some fixes. The build will continue without it.")
        set(NS3_PYTORCH OFF)
    endif()

    #Set C++ standard
    if(${NS3_PYTORCH})
        set(CMAKE_CXX_STANDARD 11) #c++17 for inline variables in Windows
        set(CMAKE_CXX_STANDARD_REQUIRED OFF) #ABI requirements for PyTorch affect this
        add_definitions(-D_GLIBCXX_USE_CXX11_ABI=0 -Dtorch_EXPORTS -DC10_BUILD_SHARED_LIBS -DNS3_PYTORCH)
    endif()

    if(${NS3_SANITIZE})
        #set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address,leak,thread,undefined,memory -g")
    endif()


    #find required dependencies
    list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/buildsupport/custom_modules")

    set(NOT_FOUND_MSG  "is required and couldn't be found")

    #Libpcre2 for regex
    #todo: fix rocketfuel topology
    #include(${PROJECT_SOURCE_DIR}/buildsupport/custom_modules/FindPCRE.cmake)
    #find_package(PCRE)
    #if (NOT ${AUTOINSTALL_DEPENDENCIES})
    #    message(WARNING "PCRE2 ${NOT_FOUND_MSG}. Rocketfuel topology reader wont be built")
    #else()
    #    #If we don't find installed, install
    #    add_package(pcre2)
    #    find_package(PCRE)
    #    include_directories(${PCRE_INCLUDE_DIRS})
    #endif()





    #GTK2
    # Don't search for it if you don't have it installed, as it take an insane amount of time
    if(${NS3_GTK2})
        find_package(GTK2)
        if(NOT ${GTK2_FOUND})
            message(WARNING "LibGTK2 was not found. Continuing without it.")
        else()
            link_directories(${GTK2_LIBRARY_DIRS})
            include_directories( ${GTK2_INCLUDE_DIRS})
            add_definitions(${GTK2_CFLAGS_OTHER})
        endif()
    endif()



    #LibRT
    if(${NS3_REALTIME})
        if(WIN32 OR APPLE)
            message(WARNING "Lib RT is not supported on Windows/Mac OS X, building without it")
            set(NS3_REALTIME OFF)
        else()
            find_library(LIBRT rt)
            if(NOT ${LIBRT_FOUND})
                message(FATAL_ERROR LibRT not found)
            else()
                link_libraries(rt)
                set(HAVE_RT TRUE) # for core-config.h
            endif()
        endif()
    endif()

    #removing pthreads in favor of C++ threads without proper testing was a bad idea
    if(${NS3_PTHREAD})
        set(THREADS_PREFER_PTHREAD_FLAG)
        find_package(Threads)
        if(${CMAKE_USE_PTHREADS_INIT})
            include_directories(${THREADS_PTHREADS_INCLUDE_DIR})
            if(${MSVC})
                set(THREADS_FOUND FALSE)
            else()
                set(PTHREADS_FOUND TRUE)
                set(HAVE_PTHREAD_H TRUE) # for core-config.h
            endif()
        else()
            set(PTHREADS_FOUND FALSE)
        endif()
    endif()


    if(${NS3_PYTHON})
         find_package (Python3 COMPONENTS Interpreter Development)


         link_directories(${Python3_LIBRARY_DIRS})
         include_directories( ${Python3_INCLUDE_DIRS})

         if(Python3::Python)
             set(PYTHONDIR TRUE)
             set(PYTHONDIR_STRING Python3_SITELIB)
             set(PYTHONARCHDIR TRUE)
             set(PYTHONARCHDIR_STRING Python3_SITEARCH)
             set(HAVE_PYEMBED  TRUE)
             set(HAVE_PYEXT    TRUE)
             set(HAVE_PYTHON_H TRUE)
         endif()
    endif()
    #Process config-store-config
    configure_file(buildsupport/config-store-config-template.h ${CMAKE_HEADER_OUTPUT_DIRECTORY}/config-store-config.h)


    if(${NS3_MPI})
        find_package(MPI)
        if(NOT ${MPI_FOUND})
            message(WARNING "MPI was not found. Continuing without it.")
            set(NS3_MPI OFF)
        else()
            include_directories( ${MPI_CXX_INCLUDE_PATH}) 
            add_definitions(${MPI_CXX_COMPILE_FLAGS} ${MPI_CXX_LINK_FLAGS} -DNS3_MPI) 
            link_libraries(${MPI_CXX_LIBRARIES}) 
            #set(CMAKE_CXX_COMPILER ${MPI_CXX_COMPILER}) 
        endif()
    endif()

    if(${NS3_GSL})
        find_package(GSL)
        if (NOT ${GSL_FOUND})
            message(WARNING "GSL was not found. Continuing without it.")
            set(NS3_GSL OFF)
        else()
            include_directories(${GSL_INCLUDE_DIRS})
            link_libraries(${GSL_LIBRARIES})
        endif()
    endif()

    if (${NS3_NETANIM})
        find_package(Qt4 COMPONENTS QtGui )
        find_package(Qt5 COMPONENTS Core Widgets PrintSupport Gui )

        if((NOT ${Qt4_FOUND}) AND (NOT ${Qt5_FOUND}))
            message(WARNING "You need Qt installed to build NetAnim. Continuing without it.")
            set(NS3_NETANIM OFF)
        else()
            if(${MSVC})
                set(${NS3_NETANIM} OFF)
                message(WARNING "Not building netanim with MSVC")
            else()
                list(APPEND 3rd_party_libraries_to_build netanim)
            endif()
        endif()
    endif()

    if(${NS3_PYTORCH})
        #Decide which version of libtorch should be downloaded.
        #If you change the build_type, remember to download both libtorch folder and libtorch.zip to redownload the appropriate version
        if(WIN32)
            if(${build_type} STREQUAL "rel")
                set(libtorch_url https://download.pytorch.org/libtorch/cpu/libtorch-win-shared-with-deps-latest.zip)
            else()
                set(libtorch_url https://download.pytorch.org/libtorch/cpu/libtorch-win-shared-with-deps-debug-latest.zip)
            endif()
        elseif(APPLE)
            set(libtorch_url https://download.pytorch.org/libtorch/cpu/libtorch-macos-latest.zip)
        else()
            set(libtorch_url https://download.pytorch.org/libtorch/cpu/libtorch-shared-with-deps-latest.zip)
        endif()

        #Define executables to download and unzip libtorch archive
        if (WIN32)
            set(CURL_EXE curl.exe)
            if(${MSVC})
                set(UNZIP_EXE  powershell expand-archive)
                set(UNZIP_POST .\\)
            else()
                set(UNZIP_EXE unzip.exe)
                set(UNZIP_POST )
            endif()
        else()
            set(CURL_EXE curl)
            set(UNZIP_EXE unzip)
            set(UNZIP_POST )
        endif()

        #Download libtorch archive if not already downloaded
        if (EXISTS ${THIRD_PARTY_DIRECTORY}/libtorch.zip)
            message(STATUS "Libtorch already downloaded")
        else()
            message(STATUS "Downloading libtorch files ${libtorch_url}")
            execute_process(COMMAND ${CURL_EXE} ${libtorch_url} --output libtorch.zip
                WORKING_DIRECTORY ${THIRD_PARTY_DIRECTORY})
        endif()

        #Extract libtorch.zip into the libtorch folder
        if (EXISTS ${THIRD_PARTY_DIRECTORY}/libtorch)
            message(STATUS "Libtorch folder already unzipped")
        else()
            message(STATUS "Unzipping libtorch files")
            execute_process(COMMAND ${UNZIP_EXE} libtorch.zip ${UNZIP_POST}
                WORKING_DIRECTORY ${THIRD_PARTY_DIRECTORY})
        endif()

        #Append the libtorch cmake folder to the CMAKE_PREFIX_PATH (enables FindTorch.cmake)
        list(APPEND CMAKE_PREFIX_PATH "${THIRD_PARTY_DIRECTORY}/libtorch/share/cmake")

        #Torch automatically includes the GNU ABI thing that causes problems (look for PYTORCH references above)
        set(backup_cxx_flags ${CMAKE_CXX_FLAGS})
        find_package(Torch REQUIRED)
        set(CMAKE_CXX_FLAGS ${backup_cxx_flags})

        #Include the libtorch includes and libraries folders
        include_directories(${TORCH_INCLUDE_DIRS})
        link_directories(${THIRD_PARTY_DIRECTORY}/libtorch/lib)

        #Torch flags may cause problems to other libraries, so undo them (TorchConfig.cmake)
        set(TORCH_CXX_FLAGS)
        set_property(TARGET torch PROPERTY INTERFACE_COMPILE_OPTIONS)
    endif()

    if(${NS3_GNUPLOT})
        find_package(Gnuplot-ios) #Not sure what package would contain the correct header/library
        if(NOT ${GNUPLOT_FOUND})
            message(WARNING "GNUPLOT was not found. Continuing without it.")
            set(NS3_GNUPLOT OFF)
        else()
            include_directories(${GNUPLOT_INCLUDE_DIRS})
            link_directories(${GNUPLOT_LIBRARY})
        endif()
    endif()

    #add_package(eigen3)
    #get_property(eigen3_dir GLOBAL PROPERTY DIR_eigen3)
    #include_directories(${eigen3_dir}/include)

    #Process core-config
    set(INT64X64 "128")
    if(${MSVC})
        #MSVC doesn't support 128 bit soft operations, which is weird since they support 128 bit numbers...
        #Clang does support, but didn't expose them https://reviews.llvm.org/D41813
        set(INT64X64 "CAIRO")
    endif()

    if(INT64X64 STREQUAL "128")
        include(buildsupport/custom_modules/FindInt128.cmake)
        FIND_INT128_TYPES()
        if(UINT128_FOUND)
            set(HAVE___UINT128_T TRUE)
            set(INT64X64_USE_128 TRUE)
        else()
            message(WARNING "Int128 not found. Falling back to CAIRO.")
            set(INT64X64 "CAIRO")
        endif()
    elseif(INT64X64 STREQUAL "DOUBLE")
        #WSLv1 has a long double issue that will result in at least 5 tests crashing https://github.com/microsoft/WSL/issues/830
        include(CheckTypeSize)
        CHECK_TYPE_SIZE("double" SIZEOF_DOUBLE)
        CHECK_TYPE_SIZE("long double" SIZEOF_LONG_DOUBLE)
        if (${MSVC})
            set(INT64X64_USE_DOUBLE TRUE) # MSVC is special (not in a good way) and uses 64 bit long double. This will break things.
        else()
            if (${SIZEOF_LONG_DOUBLE} EQUAL ${SIZEOF_DOUBLE})
                message(WARNING "Long double has the wrong size: LD ${SIZEOF_LONG_DOUBLE} vs D ${SIZEOF_DOUBLE}. Falling back to CAIRO.")
                set(INT64X64 "CAIRO")
            else()
                set(INT64X64_USE_DOUBLE TRUE)
            endif()
        endif()
    endif()

    if(INT64X64 STREQUAL "CAIRO")
        set(INT64X64_USE_CAIRO TRUE)
    endif()

    if(${NS3_DOCS})
    find_package(Doxygen REQUIRED dot dia)
    find_package(Sphinx)
        if(NOT ${DOXYGEN_FOUND})
            message(WARNING "Doxygen was not found. Continuing without documentation.")
            set(NS3_DOCS OFF)
        endif()
        if(NOT ${SPHINX_FOUND})
            message(WARNING "Sphinx was not found. Continuing without it.")
        endif()
        if (${DOXYGEN_FOUND})
            #Get introspected doxygen
            add_custom_target(run-print-introspected-doxygen
                COMMAND ${CMAKE_COMMAND} -E env ${CMAKE_OUTPUT_DIRECTORY}/utils/print-introspected-doxygen > ${PROJECT_SOURCE_DIR}/doc/introspected-doxygen.h
                DEPENDS print-introspected-doxygen
                )
            add_custom_target(run-introspected-command-line
                                COMMAND ${CMAKE_COMMAND} -E env NS_COMMANDLINE_INTROSPECTION=".." ${Python3_EXECUTABLE} ./test.py --nowaf --constrain=example
                                WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                                DEPENDS test-runner #todo: should depend on individual examples
                                )
            file(WRITE ${PROJECT_SOURCE_DIR}/doc/introspected-command-line.h "/* This file is automatically generated by
                                                                                CommandLine::PrintDoxygenUsage() from the CommandLine configuration
                                                                                in various example programs.  Do not edit this file!  Edit the
                                                                                CommandLine configuration in those files instead.
                                                                                */
                                                                                \n")
            if(WIN32)
                set(cat_command type)
            else()
                set(cat_command cat)
            endif()
            add_custom_target(assemble-introspected-command-line
                    # works on CMake 3.18 or newer > COMMAND ${CMAKE_COMMAND} -E cat ${PROJECT_SOURCE_DIR}/testpy-output/*.command-line > ${PROJECT_SOURCE_DIR}/doc/introspected-command-line.h
                    COMMAND ${cat_command} ${PROJECT_SOURCE_DIR}/testpy-output/*.command-line > ${PROJECT_SOURCE_DIR}/doc/introspected-command-line.h 2> NULL
                    DEPENDS run-introspected-command-line
                    )

            add_custom_target(doxygen
                    COMMAND Doxygen::doxygen ${PROJECT_SOURCE_DIR}/doc/doxygen.conf
                    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
                    DEPENDS run-print-introspected-doxygen assemble-introspected-command-line
            )

            if (${SPHINX_FOUND})
                set(SPHINX_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/docs/sphinx)
                add_custom_target(sphinx ALL
                        COMMAND ${SPHINX_EXECUTABLE} -b html
                        # Tell Breathe where to find the Doxygen output
                        -Dbreathe_projects.NS3=${DOXYGEN_OUTPUT_DIRECTORY}
                        ${PROJECT_SOURCE_DIR} ${SPHINX_OUTPUT_DIRECTORY}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                        COMMENT "Generating documentation with Sphinx"
                        DEPENDS doxygen)
            endif()
        endif()
    endif()

    include(CheckIncludeFileCXX)
    include(CheckFunctionExists)

    #Check for required headers and functions, set flags if they're found or warn if they're not found
    check_include_file_cxx("stdint.h"           "HAVE_STDINT_H"   )
    check_include_file_cxx("inttypes.h"         "HAVE_INTTYPES_H" )
    check_include_file_cxx("sys/types.h"        "HAVE_SYS_TYPES_H")
    check_include_file_cxx("stat.h"             "HAVE_SYS_STAT_H" )
    check_include_file_cxx("dirent.h"           "HAVE_DIRENT_H"   )
    check_include_file_cxx("stdlib.h"           "HAVE_STDLIB_H"   )
    check_include_file_cxx("signal.h"           "HAVE_SIGNAL_H"   )
    check_include_file_cxx("netpacket/packet.h" "HAVE_PACKETH"    )
    check_function_exists ("getenv"             "HAVE_GETENV"     )

    configure_file(buildsupport/core-config-template.h ${CMAKE_HEADER_OUTPUT_DIRECTORY}/core-config.h)

    #Disable NS3_EMU if netpacket isn't present
    if(NOT ${HAVE_PACKETH})
        message(WARNING "netpacket/packet.h not found. Building without EMU support.")
        set(NS3_EMU OFF)
    endif()

    #Enable NS3 logging if requested
    if(${NS3_LOG})
        add_definitions(-DNS3_LOG_ENABLE)
    endif()

    if(${NS3_ASSERT})
        add_definitions(-DNS3_ASSERT_ENABLE)
    endif()

    #Enable examples as tests (enabled by default in mainstream ns-3-dev, but replaced here with CTests)
    if(${NS3_EXAMPLES})
        set(NS3_ENABLE_EXAMPLES "1")
        add_definitions(-DNS3_ENABLE_EXAMPLES)
    endif()

    #Remove from libs_to_build all incompatible libraries or the ones that dependencies couldn't be installed
    if(${MSVC})
        set(NS3_NETANIM OFF)
    endif()

    if(NOT ${NS3_OPENFLOW})
        list(REMOVE_ITEM libs_to_build openflow)
    endif()

    if(NOT ${NS3_PYTHON})
        list(REMOVE_ITEM libs_to_build visualizer)
    endif()

    if(NOT ${NS3_BRITE})
        list(REMOVE_ITEM libs_to_build brite)
    endif()

    if (WIN32 OR APPLE OR WSLv1)
        if(${NS3_BRITE})
            set(NS3_BRITE OFF)
            list(REMOVE_ITEM libs_to_build brite)
        endif()
        list(REMOVE_ITEM libs_to_build fd-net-device)
        list(REMOVE_ITEM libs_to_build tap-bridge)
        message(WARNING "Platform doesn't support TAP, EMU or Brite features. Continuing without them.")
        set(NS3_EMU OFF)
        set(NS3_TAP OFF)
    endif()

    #Create library names to solve dependency problems with macros that will be called at each lib subdirectory
    set(ns3-libs )
    set(ns3-libs-tests )
    set(ns3-contrib-libs )
    set(lib-ns3-static-objs)
    set(ns3-python-bindings ns${NS3_VER}-pybindings-${build_type})
    set(ns3-python-bindings-modules )

    foreach(libname ${libs_to_build})
        #Create libname of output library of module
        set(lib${libname} ns${NS3_VER}-${libname}-${build_type})
        set(lib${libname}-obj ns${NS3_VER}-${libname}-${build_type}-obj)
        #list(APPEND ns3-libs ${lib${libname}})

        if( NOT (${libname} STREQUAL "test") )
            list(APPEND lib-ns3-static-objs $<TARGET_OBJECTS:${lib${libname}-obj}>)
        endif()

    endforeach()

    #Create new lib for NS3 static builds
    set(lib-ns3-static ns${NS3_VER}-static-${build_type})

    #string (REPLACE ";" " " libs_to_build_txt "${libs_to_build}")
    #add_definitions(-DNS3_MODULES_PATH=${libs_to_build_txt})

    #Dump definitions for later use
    get_directory_property( ADDED_DEFINITIONS COMPILE_DEFINITIONS )
    file(WRITE ${CMAKE_HEADER_OUTPUT_DIRECTORY}/ns3-definitions "${ADDED_DEFINITIONS}")

    #All contrib libraries can be linked afterwards linking with ${ns3-contrib-libs}
    process_contribution("${contribution_libraries_to_build}")
endmacro()

macro (write_module_header name header_files)
    string(TOUPPER ${name} uppercase_name)
    string(REPLACE "-" "_" final_name ${uppercase_name} )
    #Common module_header
    list(APPEND contents "#ifdef NS3_MODULE_COMPILATION ")
    list(APPEND contents  "
    error \"Do not include ns3 module aggregator headers from other modules; these are meant only for end user scripts.\" ")
    list(APPEND contents  "
#endif ")
    list(APPEND contents "
#ifndef NS3_MODULE_")
    list(APPEND contents ${final_name})
    list(APPEND contents "
    // Module headers: ")

    #Write each header listed to the contents variable
    foreach(header ${header_files})
        get_filename_component(head ${header} NAME)
        list(APPEND contents
                "
    #include <ns3/${head}>")
        ##include \"ns3/${head}\"")
    endforeach()

    #Common module footer
    list(APPEND contents "
#endif ")
    file(WRITE ${CMAKE_HEADER_OUTPUT_DIRECTORY}/${name}-module.h ${contents})
endmacro()


macro (build_lib libname source_files header_files libraries_to_link test_sources)

    #Create object library with sources and headers, that will be used in lib-ns3-static and the shared library
    #add_library(${lib${libname}-obj} OBJECT "${source_files}" "${header_files}") # commented out to reduce number of targets, required by NS3_STATIC

    GET_PROPERTY(local-ns3-libs GLOBAL PROPERTY ns3-libs)
    set_property(GLOBAL PROPERTY ns3-libs "${local-ns3-libs};${lib${libname}}")

    #Create shared library with previously created object library (saving compilation time for static libraries)
    #add_library(${lib${libname}} SHARED $<TARGET_OBJECTS:${lib${libname}-obj}>) # commented out to reduce number of targets, required by NS3_STATIC
    add_library(${lib${libname}} SHARED "${source_files}" "${header_files}")

    #Link the shared library with the libraries passed
    target_link_libraries(${lib${libname}} ${LIB_AS_NEEDED_PRE} "${libraries_to_link}" ${LIB_AS_NEEDED_POST})

    if(${MSVC})
        # /OPT:NOREF prevents the compiler and linker from removing unused symbols/functions
        target_link_options(${lib${libname}} PUBLIC /OPT:NOREF)
    endif()

    #Write a module header that includes all headers from that module
    write_module_header("${libname}" "${header_files}")

    #Copy all header files to outputfolder/include
    file(COPY ${header_files} DESTINATION ${CMAKE_HEADER_OUTPUT_DIRECTORY})

    #Build tests if requested
    if(${NS3_TESTS})
        list(LENGTH test_sources test_source_len)
        if (${test_source_len} GREATER 0)
            #Create libname of output library test of module
            set(test${libname} ns${NS3_VER}-${libname}-test-${build_type} CACHE INTERNAL "" FORCE)

            GET_PROPERTY(local-ns3-libs-tests GLOBAL PROPERTY ns3-libs-tests)
            if (WIN32)
                set_property(GLOBAL PROPERTY ns3-libs-tests "${local-ns3-libs-tests};$<TARGET_OBJECTS:${test${libname}}>")

                #Create shared library containing tests of the module
                add_library(${test${libname}} OBJECT "${test_sources}")
            else()
                set_property(GLOBAL PROPERTY ns3-libs-tests "${local-ns3-libs-tests};${test${libname}}")

                #Create shared library containing tests of the module
                add_library(${test${libname}} SHARED "${test_sources}")

                #Link test library to the module library
                target_link_libraries(${test${libname}} ${LIB_AS_NEEDED_PRE} ${lib${libname}} "${libraries_to_link}" ${LIB_AS_NEEDED_POST})
            endif()

            target_compile_definitions(${test${libname}} PRIVATE NS_TEST_SOURCEDIR="src/${libname}/test")
        endif()
    endif()

    #Build lib examples if requested
    if(${NS3_EXAMPLES})
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/examples)
            add_subdirectory(examples)
        endif()
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/example)
            add_subdirectory(example)
        endif()
    endif()

    #Build pybindings if requested and if bindings subfolder exists in NS3/src/libname
    if(${NS3_PYTHON} AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/bindings")
        set(arch gcc_LP64)#ILP32)
        #todo: fix python module names, output folder and missing links
        set(module_src ns3module.cc)
        set(module_hdr ns3module.h)

        string(REPLACE "-" "_" libname_sub input) # - causes problems (e.g. csma-layout) causes problems, rename to _ (e.g. csma_layout)

        set(modulegen_modular_command  python2 ${CMAKE_SOURCE_DIR}/bindings/python/ns3modulegen-modular.py ${CMAKE_CURRENT_SOURCE_DIR} ${arch} ${libname_sub} ${CMAKE_CURRENT_SOURCE_DIR}/bindings/${module_src})
        set(modulegen_arch_command python2 ${CMAKE_CURRENT_SOURCE_DIR}/bindings/modulegen__${arch}.py 2> ${CMAKE_CURRENT_SOURCE_DIR}/bindings/ns3modulegen.log)

        execute_process(
                COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${CMAKE_OUTPUT_DIRECTORY} ${modulegen_modular_command}
                COMMAND ${CMAKE_COMMAND} -E env PYTHONPATH=${CMAKE_OUTPUT_DIRECTORY} ${modulegen_arch_command}
                TIMEOUT 60
                #WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                #OUTPUT_FILE ${CMAKE_CURRENT_SOURCE_DIR}/bindings/${module_src}
                RESULT_VARIABLE res
                OUTPUT_QUIET
                ERROR_QUIET
        )

        #message(WARNING ${res})

        set(python_module_files ${CMAKE_CURRENT_SOURCE_DIR}/bindings/${module_hdr} ${CMAKE_CURRENT_SOURCE_DIR}/bindings/${module_src})
        if(${libname} STREQUAL "core")
            list(APPEND python_module_files ${CMAKE_CURRENT_SOURCE_DIR}/bindings/module_helpers.cc ${CMAKE_CURRENT_SOURCE_DIR}/bindings/scan-header.h)
        endif()

        #message(WARNING ${python_module_files})
        add_library(ns3module_${libname} OBJECT "${python_module_files}")
        set(ns3-python-bindings-modules ${ns3-python-bindings-modules} $<TARGET_OBJECTS:ns3module_${libname}> CACHE INTERNAL "" FORCE)
    endif()
endmacro()



function(set_runtime_outputdirectory target_name output_directory)
    #message(FATAL_ERROR "${target_name} ${output_directory}")
    GET_PROPERTY(local-ns3-executables GLOBAL PROPERTY ns3-execs)
    set_property(GLOBAL PROPERTY ns3-execs "${local-ns3-executables};${output_directory}${target_name}")

    set_target_properties( ${target_name}
            PROPERTIES
            RUNTIME_OUTPUT_DIRECTORY ${output_directory}
            )
    if(${MSVC} OR ${XCODE})
        #Is that so hard not to break people's CI, MSFT and AAPL??
        #Why would you output the targets to a Debug/Release subfolder? Why?
        foreach( OUTPUTCONFIG ${CMAKE_CONFIGURATION_TYPES} )
            string( TOUPPER ${OUTPUTCONFIG} OUTPUTCONFIG )
            set_target_properties( ${target_name}
                    PROPERTIES
                    RUNTIME_OUTPUT_DIRECTORY_${OUTPUTCONFIG} ${output_directory}
                    )
        endforeach( OUTPUTCONFIG CMAKE_CONFIGURATION_TYPES )
    endif()
endfunction(set_runtime_outputdirectory)

function(create_test test_name test_id test_arguments working_directory)
    #message(WARNING "${test_name} ${test_id} ${test_arguments} ${working_directory}")
    # test.py assume the binary is executed inside the ns-3-dev folder, or ${PROJECT_SOURCE_DIR} in CMake land
    # I preferred to execute within the build/example or build/src/module/example folders, passed as ${working_directory}), keeping all output files inside the build/bin folder
    if(WIN32)
        #Windows require this workaround to make sure the DLL files are located
        add_test(NAME ctest-${test_name}-${test_id}
                COMMAND ${CMAKE_COMMAND} -E env "PATH=$ENV{PATH};${CMAKE_RUNTIME_OUTPUT_DIRECTORY};${CMAKE_LIBRARY_OUTPUT_DIRECTORY}" ${test_name} ${test_arguments}
                WORKING_DIRECTORY ${working_directory})
    else()
        add_test(NAME ctest-${test_name}-${test_id}
                COMMAND ${test_name} ${test_arguments}
                WORKING_DIRECTORY ${working_directory})
    endif()
endfunction(create_test)

function(process_tests ignore_example test_name examples_list output_directory)
    if(ignore_example)
    else()
        if(NOT examples_list)
            create_test(${test_name} 0 "" ${output_directory})
        else()
            #If arguments for the examples were defined, create a case for each set of parameters
            set(num_examples 0)
            foreach(example ${examples_list})
                #Turn string into list of parameters and remove program name to replace with absolute path
                string(REPLACE " " ";" example ${example})
                list(REMOVE_AT example 0)
                create_test("${test_name}" "${num_examples}" "${example}" "${output_directory}")
                MATH(EXPR num_examples "${num_examples}+1")
            endforeach()
        endif()
    endif()
endfunction(process_tests)


include(buildsupport/custom_modules/ns3_extract_examples_to_run_arguments.cmake)


macro (build_lib_example name source_files header_files libraries_to_link files_to_copy)
    #Create shared library with sources and headers
    add_executable(${name} "${source_files}" "${header_files}")

    #Link the shared library with the libraries passed
    target_link_libraries(${name} ${LIB_AS_NEEDED_PRE} ${lib${libname}} ${libraries_to_link} ${LIB_AS_NEEDED_POST})
    set_runtime_outputdirectory(${name} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/src/${libname}/examples/)

    file(COPY ${files_to_copy} DESTINATION ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/src/${libname}/examples/)

    process_tests("${ignore_example}" "${name}" "${examples}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/src/${libname}/examples/")
    unset(examples)
endmacro()

macro (build_example name source_files header_files libraries_to_link)
    #Create shared library with sources and headers
    add_executable(${name} "${source_files}" "${header_files}")

    #Link the shared library with the libraries passed
    target_link_libraries(${name}  ${LIB_AS_NEEDED_PRE} ${libraries_to_link} ${LIB_AS_NEEDED_POST})
    set_runtime_outputdirectory(${name} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/examples/${examplefolder}/)

    process_tests("${ignore_example}" "${name}" "${examples}" "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/examples/${examplefolder}/")
    unset(examples)
endmacro()


#Waf workaround scripts
include(buildsupport/custom_modules/waf_workaround_c4cache.cmake)
include(buildsupport/custom_modules/waf_workaround_buildstatus.cmake)
include(buildsupport/custom_modules/waf_workaround_lock.cmake)

#Add contributions macros
include(buildsupport/contributions.cmake)

