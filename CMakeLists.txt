cmake_minimum_required(VERSION 3.12)
project(lupafromlua)

# Find Lua static library
find_package(Lua 5.0 REQUIRED MODULE)

# Find Python dynamic library
set(Python_USE_STATIC_LIBS FALSE)
find_package(Python 3.5 REQUIRED COMPONENTS Development)

# Add source code
add_subdirectory(src)
