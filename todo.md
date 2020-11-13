# To do list

* Write a CMakeLists.txt that finds Lua :ok:
* Add a library to CMakeLists.txt that links to Lua :ok:
* Write a Lua library in C :ok:
* Make CMake find the Python libraries :ok:
* Make the library link against Python :ok:
* In the library, initialize and finalize Python :ok:
* In the library, print Hello World from Python :ok:
* In the library, import Lupa from Python :ok:

  * In this step, I stumbled upon an issue which prevents Python from finding the
    Lupa module through the C API in a shared module. This has been addressed before [(1)] [(4)] [(5)].
    The solution is linking dynamically against the Python runtime library with `dlopen`. This has
    also been done before in bastibe's fork of Lunatic Python [(2)]. The Python runtime library name
    is obtained by CMake, defined as a macro (`PYTHON_LIBRT`) in C so that it can be passed to `dlopen` [(3)].
    The flags passed to `dlopen` are `RTLD_NOW` (resolve all symbols before `dlopen` returns) and `RTLD_GLOBAL`
    (symbols are available to dynamic libraries subsequently loaded).

* Have the Lupa project locally :ok:
* Setup the Lupa library locally
* Import Lupa locally from Python
* Modify Lupa so that LuaRuntime can accept an already existent Lua state
* In the library, create a LuaRuntime with the already existent Lua state
* In the library, attribute this LuaRuntime to a variable "lua" in Python
* Make the library return a table with the "python" table

[(1)]: https://mail.python.org/pipermail/new-bugs-announce/2008-November/003322.html
[(2)]: https://github.com/bastibe/lunatic-python/blob/master/src/pythoninlua.c#L641
[(3)]: https://www.man7.org/linux/man-pages/man3/dlopen.3.html
[(4)]: https://stackoverflow.com/questions/29880931/importerror-and-pyexc-systemerror-while-embedding-python-script-within-c-for-pam
[(5)]: https://sourceforge.net/p/pam-python/code/ci/default/tree/src/pam_python.c#l2507
