cmake_minimum_required(VERSION 3.12)
project(lupafromlua)

# Find Lua static library
find_package(Lua 5.0 REQUIRED MODULE)

# Find Python dynamic library
set(Python_USE_STATIC_LIBS FALSE)
find_package(Python 3.5 REQUIRED COMPONENTS Interpreter Development)

# Get Pyhon extension module suffix
execute_process(
	COMMAND "${Python_EXECUTABLE}" -c "import sysconfig; print(sysconfig.get_config_vars()['SO'], end='')"
	OUTPUT_VARIABLE PYTHON_EXT_SUFFIX
	RESULT_VARIABLE PYTHON_EXT_SUFFIX_NOT_FOUND)

if(PYTHON_EXT_SUFFIX_NOT_FOUND)
	message(FATAL_ERROR "Could not obtain Python extension module suffix")
endif()

set(LUPA_PROJECT_DIR "${PROJECT_SOURCE_DIR}/lupa")
set(LUPA_SOURCE_DIR "${LUPA_PROJECT_DIR}/lupa")
set(LUPA_BINARY_FILE "${LUPA_SOURCE_DIR}/_lupa${PYTHON_EXT_SUFFIX}")

file(GLOB_RECURSE LUPA_SOURCE_FILES
	"${LUPA_SOURCE_DIR}/*.pyx"
	"${LUPA_SOURCE_DIR}/*.pxd"
	"${LUPA_SOURCE_DIR}/*.pxi")

file(GLOB_RECURSE LUPA_GENERATED_FILES
	"${LUPA_SOURCE_DIR}/*.c")

# Build lupa
add_custom_command(
	OUTPUT "${LUPA_BINARY_FILE}"
	COMMAND "${CMAKE_COMMAND}" -E rm -f ${LUPA_GENERATED_FILES}
	COMMAND "${Python_EXECUTABLE}" -m pip install -r requirements.txt
	COMMAND "${Python_EXECUTABLE}" setup.py develop --use-bundle
	WORKING_DIRECTORY "${LUPA_PROJECT_DIR}"
	DEPENDS "${LUPA_SOURCE_FILES}"
	COMMENT "Setting up lupa in development mode"
	VERBATIM)

add_custom_target(lupa ALL DEPENDS "${LUPA_BINARY_FILE}")

# Add source code
add_subdirectory(src)
