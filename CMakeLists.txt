cmake_minimum_required(VERSION 3.18)
project(lupafromlua)

option(LUPA_DEBUG_GC "Print debug information about garbage collection in Lupa" OFF)

set(LUPAFROMLUA_PROJECT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

# Find Lua static library
find_package(Lua REQUIRED MODULE)

if("${LUA_VERSION_STRING}" VERSION_LESS "5.1")
	message(WARNING "Versions of Lua previous to 5.1 might be incompatible")
endif()

# Find Python dynamic library and executable
set(Python_USE_STATIC_LIBS FALSE)
find_package(Python REQUIRED COMPONENTS Interpreter Development)

if("${Python_VERSION}" VERSION_LESS "2.7")
	message(WARNING "Versions of Python previous to 2.7 might be incompatible")
elseif("${Python_VERSION}" VERSION_GREATER_EQUAL "3" AND "${Python_VERSION}" VERSION_LESS "3.5")
	message(WARNING "Versions of Python 3 previous to 3.5 might be incompatible")
endif()

# Get Python extension module suffix
execute_process(
	COMMAND "${Python_EXECUTABLE}" "${LUPAFROMLUA_PROJECT_DIR}/src/ext.py"
	OUTPUT_VARIABLE PYTHON_EXT_SUFFIX
	RESULT_VARIABLE PYTHON_EXT_SUFFIX_NOT_FOUND) 

if(PYTHON_EXT_SUFFIX_NOT_FOUND)
	message(FATAL_ERROR "Could not obtain Python extension module suffix")
endif()

set(LUPA_PROJECT_DIR "${LUPAFROMLUA_PROJECT_DIR}/lupa")
set(LUPA_SOURCE_DIR "${LUPA_PROJECT_DIR}/lupa")
set(LUPA_BINARY_FILE "${LUPA_SOURCE_DIR}/_lupa${PYTHON_EXT_SUFFIX}")

file(GLOB_RECURSE LUPA_SOURCE_FILES
	"${LUPA_SOURCE_DIR}/*.pyx"
	"${LUPA_SOURCE_DIR}/*.pxd"
	"${LUPA_SOURCE_DIR}/*.pxi")

file(GLOB_RECURSE LUPA_GENERATED_FILES
	"${LUPA_SOURCE_DIR}/*.c")

# Lua include directory
set(LUPA_BUILD_ARGS "--lua-inc-dir" "${LUA_INCLUDE_DIR}")

foreach(LUA_LIBRARY ${LUA_LIBRARIES})
	# Lua library directory
	get_filename_component(LUA_LIBRARY_DIR ${LUA_LIBRARY} DIRECTORY)

	if(NOT "${LUA_LIBRARY_DIR}" STREQUAL "")
		list(APPEND LUPA_BUILD_ARGS "--lua-lib-dir" "${LUA_LIBRARY_DIR}")
	endif()

	# Lua library name
	get_filename_component(LUA_LIBRARY_NAME ${LUA_LIBRARY} NAME_WLE)
	string(REGEX REPLACE "^lib" "" LUA_LIBRARY_NAME "${LUA_LIBRARY_NAME}")
	list(APPEND LUPA_BUILD_ARGS "--lua-lib" "${LUA_LIBRARY_NAME}")
endforeach()

if(LUPA_DEBUG_GC)
	list(APPEND LUPA_BUILD_ARGS "--debug-gc")
endif()

# Build lupa
add_custom_command(
	OUTPUT "${LUPA_BINARY_FILE}"
	COMMAND "${CMAKE_COMMAND}" -E rm -f ${LUPA_GENERATED_FILES} "${LUPA_BINARY_FILE}"
	COMMAND "${Python_EXECUTABLE}" -m pip install -r requirements.txt
	COMMAND "${Python_EXECUTABLE}" setup.py build ${LUPA_BUILD_ARGS} develop --user
	WORKING_DIRECTORY "${LUPA_PROJECT_DIR}"
	DEPENDS "${LUPA_SOURCE_FILES}"
	COMMENT "Setting up lupa in development mode"
	VERBATIM)

add_custom_target(lupa ALL DEPENDS "${LUPA_BINARY_FILE}")

# Add source code
add_subdirectory(src)
