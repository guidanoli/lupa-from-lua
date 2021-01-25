# To do list

* Study the implementation of garbage collection and investigate possible memory leaks
* Study the implementation of named parameters using decorators
* Study alternative implementations of named parameters

# Done

* Write a CMakeLists.txt that finds Lua
* Add a library to CMakeLists.txt that links to Lua
* Write a Lua library in C
* Make CMake find the Python libraries
* Make the library link against Python
* In the library, initialize and finalize Python
* In the library, print Hello World from Python
* In the library, import Lupa from Python

  * In this step, I stumbled upon an issue which prevents Python from finding the
    Lupa module through the C API in a shared module. This has been addressed before [(1)] [(4)] [(5)].
    The solution is linking dynamically against the Python runtime library with `dlopen`. This has
    also been done before in bastibe's fork of Lunatic Python [(2)]. The Python runtime library name
    is obtained by CMake, defined as a macro (`PYTHON_LIBRT`) in C so that it can be passed to `dlopen` [(3)].
    The flags passed to `dlopen` are `RTLD_NOW` (resolve all symbols before `dlopen` returns) and `RTLD_GLOBAL`
    (symbols are available to dynamic libraries subsequently loaded).

* Have the Lupa project locally
* Setup the Lupa library locally
* Import Lupa locally from Python
* Create a LuaRuntime object from Python
* Modify Lupa so that LuaRuntime can accept an already existent Lua state
* In the library, create a LuaRuntime with the already existent Lua state
* Make the library return a table with the "python" table
* In the library, attribute this LuaRuntime to a variable "lua" in Python
* Register a different function for eval in the Lua table for interacting with Python
* Implement a function for eval that evaluates a string in the global scope of the main module
* Implement an adaptation for exec that executes a string in the global scope of the main module
* Create a structure for testing Lupa from the Lua side
* Test all of the entries provided in the python table
* Unload Python library when python module goes out of scope in Lua
* Study and implement conversion of integers for Lua >= 5.3
* Stop using bundled Lua and pass library and include paths to lupa/setup.py directly
* Configure continuous integration service

[(1)]: https://mail.python.org/pipermail/new-bugs-announce/2008-November/003322.html
[(2)]: https://github.com/bastibe/lunatic-python/blob/master/src/pythoninlua.c#L641
[(3)]: https://www.man7.org/linux/man-pages/man3/dlopen.3.html
[(4)]: https://stackoverflow.com/questions/29880931/importerror-and-pyexc-systemerror-while-embedding-python-script-within-c-for-pam
[(5)]: https://sourceforge.net/p/pam-python/code/ci/default/tree/src/pam_python.c#l2507
