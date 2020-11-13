cmake_minimum_required(VERSION 3.0)
project(lupafromlua)

# Find Lua
find_package(Lua 5.0 REQUIRED MODULE)

if(NOT PYTHON_EXECUTABLE)
	# Find Python interpreter
	set(Python_FIND_VIRTUALENV FIRST)
	find_package(PythonInterp 3.5 REQUIRED)
endif()

# Find Python headers
exec_program(${PYTHON_EXECUTABLE}
	ARGS "-c \"import sysconfig; print(sysconfig.get_paths()['include'])\""
	OUTPUT_VARIABLE PYTHON_INCLUDE_DIRS
	RETURN_VALUE PYTHON_INCLUDE_DIRS_NOT_FOUND)

if(PYTHON_INCLUDE_DIRS_NOT_FOUND)
	message(FATAL_ERROR "Python headers not found")
endif()

# This goes after, since it uses PythonInterp as a hint
if(WIN32)
	find_package(PythonLibs 3.5 REQUIRED)
endif()

# Add source code
add_subdirectory(src)
