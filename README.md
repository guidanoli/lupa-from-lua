# Lupa from Lua

Make sure to clone this repository recursively.

```sh
git submodule update --init --recursive
```

## Dependencies

* [CMake] >= 3.12
  * program
* [Lua] >= 5.1
  * program
  * static library
* [Python] >= 3.5
  * program
  * dynamic library

## Setup

You may first configure a build system for your machine by using CMake. You may substite `$BUILDIR` for a name of your liking.

```sh
cmake -B $BUILDIR
```

If necessary, you can tweak `$BUILDIR/CMakeCache.txt` to correct libraries and include directories paths to be used. Having configured the project nicely, you may build the Lua C library.

```sh
cmake --build $BUILDIR
```

## Testing

Having built the dependencies, now you may run the test suite. A report should be printed out.

```sh
lua tests/testbench.lua
```

[CMake]: https://cmake.org/
[Lua]: https://www.lua.org/
[Python]: https://www.python.org/
