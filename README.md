# Lupa from Lua

Currently, [Lupa] is a Python extension module which can only be imported from Python. This project intends to port this library to Lua in the form of a C library, allowing Lua to interact with Python.
For this purpose, the Lupa source code had to be slightly modified in the fork that resides in this repository.

## Dependencies

* [CMake] >= 3.12
  * program
* [Lua] >= 5.1
  * program
  * static library
* [Python] 2.7 or >= 3.5
  * program
  * dynamic library

## Setup

Make sure to clone this repository recursively.

```sh
git submodule update --init --recursive
```

In order to install the Lupa fork, it is necessary to first uninstall any official release.

```sh
python -m pip uninstall lupa
```

You may first configure a build system for your machine with CMake. You can name the build directory however you like. For the sake of generality, we'll be referecing it as `$BUILD_DIR`.

```sh
cmake -B $BUILD_DIR
```

If necessary, you can tweak `$BUILD_DIR/CMakeCache.txt` to correct any path wrongly assumed by CMake. Having configured the project nicely, you may build the project.

```sh
cmake --build $BUILD_DIR
```

If you later wish to uninstall the Lupa fork, you can run the following command in the `lupa` directory.
Also, by ommitting `--uninstall`, you reinstall the module without needing to rebuild it.

```sh
python setup.py develop --uninstall --user
```

## Testing

Having built the project, you may run the test suite from the repository root. A report should be printed out.

```sh
lua tests/testbench.lua
```

[Lupa]: https://github.com/scoder/lupa
[CMake]: https://cmake.org/
[Lua]: https://www.lua.org/
[Python]: https://www.python.org/
