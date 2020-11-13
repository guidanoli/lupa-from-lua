cmake_minimum_required(VERSION 3.0)
project(lupafromlua)

# Find Lua
find_package(Lua 5.0 REQUIRED MODULE)

# Find Python
find_package(PythonLibs 3.5 REQUIRED MODULE)

# Add source code
add_subdirectory(src)
