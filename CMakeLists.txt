cmake_minimum_required(VERSION 3.14.7)
project(lupafromlua)

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
	COMMAND "${Python_EXECUTABLE}" -c "import sysconfig; print(sysconfig.get_config_var('EXT_SUFFIX'))"
	OUTPUT_VARIABLE PYTHON_EXT_SUFFIX
	RESULT_VARIABLE PYTHON_EXT_SUFFIX_NOT_FOUND) 

string(REGEX REPLACE "\n$" "" PYTHON_EXT_SUFFIX "${PYTHON_EXT_SUFFIX}")

if(PYTHON_EXT_SUFFIX_NOT_FOUND)
	message(FATAL_ERROR "Could not obtain Python extension module suffix")
endif()

set(LUPA_PROJECT_DIR "${PROJECT_SOURCE_DIR}/lupa")
set(LUPA_SOURCE_DIR "${LUPA_PROJECT_DIR}/lupa")
set(LUPA_BINARY_FILE "${LUPA_SOURCE_DIR}/_lupa${PYTHON_EXT_SUFFIX}")
set(LUA_PROJECT_DIR "${LUPA_PROJECT_DIR}/third-party/lua")

file(GLOB_RECURSE LUPA_SOURCE_FILES
	"${LUPA_SOURCE_DIR}/*.pyx"
	"${LUPA_SOURCE_DIR}/*.pxd"
	"${LUPA_SOURCE_DIR}/*.pxi")

file(GLOB_RECURSE LUPA_GENERATED_FILES
	"${LUPA_SOURCE_DIR}/*.c")

if("${CMAKE_VERSION}" VERSION_LESS "3.17.0")
	set(CMAKE_REMOVE_COMMAND remove)
else()
	set(CMAKE_REMOVE_COMMAND rm)
endif()

# Lua include directory
set(LUPA_BUILD_ARGS "--lua-inc-dir" "${LUA_INCLUDE_DIR}")

foreach(LUA_LIBRARY ${LUA_LIBRARIES})
	# Lua library directory
	get_filename_component(LUA_LIBRARY_DIR ${LUA_LIBRARY} DIRECTORY)
	list(APPEND LUPA_BUILD_ARGS "--lua-lib-dir" "${LUA_LIBRARY_DIR}")

	# Lua library name
	get_filename_component(LUA_LIBRARY_NAME ${LUA_LIBRARY} NAME_WLE)
	string(REGEX REPLACE "^lib" "" LUA_LIBRARY_NAME "${LUA_LIBRARY_NAME}")
	list(APPEND LUPA_BUILD_ARGS "--lua-lib" "${LUA_LIBRARY_NAME}")
endforeach()

# Build lupa
add_custom_command(
	OUTPUT "${LUPA_BINARY_FILE}"
	COMMAND "${CMAKE_COMMAND}" -E "${CMAKE_REMOVE_COMMAND}" -f ${LUPA_GENERATED_FILES} "${LUPA_BINARY_FILE}"
	COMMAND "${Python_EXECUTABLE}" -m pip install -r requirements.txt
	COMMAND "${Python_EXECUTABLE}" setup.py build ${LUPA_BUILD_ARGS} develop --user
	WORKING_DIRECTORY "${LUPA_PROJECT_DIR}"
	DEPENDS "${LUPA_SOURCE_FILES}"
	COMMENT "Setting up lupa in development mode"
	VERBATIM)

add_custom_target(lupa ALL DEPENDS "${LUPA_BINARY_FILE}")

# Add source code
add_subdirectory(src)
