# Lupa from Lua

<img align="right" width="200" src="logo.png">

[Lupa] is a Python extension module that allows the user to create and interact with multiple Lua runtimes from Python. Moreover, inside each Lua runtime, Lupa stores a library for interacting with Python. Our project consists of a Lua library with an embedded Python interpreter that loads Lupa, allowing Lua, as the host language, to also interact with Python. For this purpose, we had to modify the source code of Lupa as to allow Lua runtimes within Python be created from prexisting Lua states.

## Example

```lua
local python = require "lupafromlua"
assert(python.eval('3**3') == 27)
assert(python.eval('lua.eval("3^3")') == 27)
assert(python.eval('lua.eval("tostring")(13)') == '13')
local apply = python.eval('lambda f, n: f(n)')
assert(apply(function(n) return n+1 end, 10) == 11)
```

For a better understanding of the interface between Lua and Python, we invite you to head to our [Lupa fork].

## Dependencies

* [CMake](#cmake) >= 3.18
  * executable
* [Lua](#lua) >= 5.1
  * library
* [Python](#python) 2.7 or >= 3.5
  * executable
  * library

### [CMake]

#### Windows

See [CMake downloads page].

#### Linux

Example with CMake 3.18.5.

```sh
wget https://github.com/Kitware/CMake/releases/download/v3.18.5/cmake-3.18.5.tar.gz
tar -zxvf cmake-3.18.5.tar.gz
cd cmake-3.18.5
./bootstrap
make -j $(nproc)
sudo make install
```

### [Lua]

#### Windows

See [LuaBinaries page on Sourceforge].

#### Linux

Example with Lua 5.4.2.

```sh
curl -R -O http://www.lua.org/ftp/lua-5.4.2.tar.gz
tar zxf lua-5.4.2.tar.gz
cd lua-5.4.2
sed 's/\(^CFLAGS.*\)/\1 -fPIC/' -i src/Makefile
make -j $(nproc)
sudo make install
```

Example with Lua 5.4.2, by using [luav].

```sh
luav get 5.4.2
CFLAGS=-fPIC luav make 5.4.2 -j $(nproc)
luav set 5.4.2
```

### [Python]

#### Windows

See [Python Releases for Windows].

#### Linux

Example with Python 3.8.4.

```sh
wget https://www.python.org/ftp/python/3.8.4/Python-3.8.4.tgz
tar xvf Python-3.8.4.tgz
cd Python-3.8.4
./configure --enable-shared
make -j $(nproc)
sudo make altinstall
```

Example with Python 3.9 by using [pyenv].

```sh
CONFIGURE_OPTS=--enable-shared pyenv install 3.9
```

## Setup

Make sure to clone this repository recursively.

```sh
git submodule update --init --recursive
```

In order to install the Lupa fork, it is necessary to first uninstall any official release.

```sh
python -m pip uninstall lupa
```

Also, in order to build the Lupa fork, you need to install some dependencies.

```sh
python -m pip install -r requirements.txt
```

You may first configure a build system for your machine with CMake. You can name the build directory however you like. For the sake of generality, we'll be referecing it as `$BUILD_DIR`.

```sh
cmake -B $BUILD_DIR
```

If necessary, you can tweak `$BUILD_DIR/CMakeCache.txt` to correct any path wrongly assumed by CMake.
Having configured the project nicely, you may build the project in Release mode to ensure CMake links it with the Python release library, just like Lupa.

```sh
cmake --build $BUILD_DIR --config Release
```

If you later wish to uninstall the Lupa fork, you can run the following command.
Also, by ommitting `--uninstall`, you reinstall the module without needing to rebuild it.

```sh
python setup.py develop --uninstall --user # in lupa/
```

## Testing

### Lupafromlua

You can test Lupa from Lua by running the `test.lua` script with the Lua standalone.

```sh
lua test.lua
```

If you don't have the Lua standalone, you can run the tests from inside Lua by importing the `test.lua` script and calling the `safe_run` function.

```lua
local ok, err = require'test'.safe_run()
-- On success, ok = true
-- On failure, ok = false and err = error message
```

Alternatively, you can call the `run` function if you want the program to abort in case a test case fails.

```lua
require'test'.run()
```

### Lupa

You may also want to test Lupa as a Python extension.

```sh
python setup.py test # in lupa/
```

If you wish to test for different versions of python, you should use `tox`.

```sh
python -m pip install tox
tox # in lupa/
```

[Lupa]: https://github.com/scoder/lupa
[Lupa fork]: https://github.com/guidanoli/lupa
[CMake]: https://cmake.org/
[Lua]: https://www.lua.org/
[Python]: https://www.python.org/
[pyenv]: https://github.com/pyenv/pyenv
[luav]: https://github.com/guidanoli/luav
[Python Releases for Windows]: https://www.python.org/downloads/windows/
[LuaBinaries page on Sourceforge]: https://sourceforge.net/projects/luabinaries/
[CMake downloads page]: https://cmake.org/download/
