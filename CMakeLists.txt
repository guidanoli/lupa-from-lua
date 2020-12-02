cmake_minimum_required(VERSION 3.12)
project(lupafromlua)

# Find Lua static library
find_package(Lua 5.0 REQUIRED MODULE)

# Find Python dynamic library
set(Python_USE_STATIC_LIBS FALSE)
find_package(Python 3.5 REQUIRED COMPONENTS Interpreter Development)

set(LUPA_PROJECT_DIR "${PROJECT_SOURCE_DIR}/lupa")
set(LUPA_SOURCE_DIR "${LUPA_PROJECT_DIR}/lupa")

# Build lupa
add_custom_command(
	OUTPUT "${LUPA_SOURCE_DIR}/_lupa.c"
	COMMAND "${CMAKE_COMMAND}" -E rm -f "${LUPA_SOURCE_DIR}/_lupa.c"
	COMMAND "${Python_EXECUTABLE}" -m pip install -r requirements.txt
	COMMAND "${Python_EXECUTABLE}" setup.py develop --use-bundle
	WORKING_DIRECTORY "${LUPA_PROJECT_DIR}"
	DEPENDS "${LUPA_SOURCE_DIR}/_lupa.pyx"
	COMMENT "Setting up lupa in development mode"
	VERBATIM)

add_custom_target(lupa ALL DEPENDS "${LUPA_SOURCE_DIR}/_lupa.c")

# Add source code
add_subdirectory(src)
