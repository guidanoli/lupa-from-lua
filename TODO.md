# To do list

* Study the implementation of named parameters using decorators
* Study alternative implementations of named parameters

# Doing

* Study the implementation of garbage collection and investigate possible memory leaks

  * There is a bug in Lupa which leads to memory leakage due to cyclic references between Lua and Python.
    These objects are indeed collected when the LuaRuntime object in Python is collected, but until then
    many of these cycles may be created, rendering plenty of memory space useless to the user. The great
    problem is to detect these reference cycles in both languages since they implement garbage collection
    quite differently, and, nonetheless, each language GC cannot "see" the full cycle.

  * Python supports cyclic garbage collection, assuming container objects have special callbacks
    and flags for traversing all the objects in it [(6)].
  
  * This problem was left open, since no good solutions could be found which would not impact the overall
    performance of the program. The very distinct natures of Lua and Python memory management systems makes
    it almost impossible to efficiently detect cycles and break them.
  
  * One key aspect is that while Lua objects can be ressurected, when you decrement the reference count of
    a Python object down to zero, it is immediately collected. This behavious cannot be changed in Python.
  
  * Even though we could not address this issue, we were able to detect one which can be fixed.
    When a userdata that references a Python object is ressurected, the Python object itself isn't, leaving a
    dangling pointer that will likely result in bad memory access. We just need to invalidate the reference
    and throw an error in Python whenever someone tries to access this reference.

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
* Study alternative handling of number conversion between Python and Lua in case of overflow

[(1)]: https://mail.python.org/pipermail/new-bugs-announce/2008-November/003322.html
[(2)]: https://github.com/bastibe/lunatic-python/blob/master/src/pythoninlua.c#L641
[(3)]: https://www.man7.org/linux/man-pages/man3/dlopen.3.html
[(4)]: https://stackoverflow.com/questions/29880931/importerror-and-pyexc-systemerror-while-embedding-python-script-within-c-for-pam
[(5)]: https://sourceforge.net/p/pam-python/code/ci/default/tree/src/pam_python.c#l2507
[(6)]: https://docs.python.org/3/c-api/gcsupport.html
