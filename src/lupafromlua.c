#include "lupafromlua.h"

#include <stdlib.h>
#include <assert.h>

#include <Python.h>
#include <lauxlib.h>

#if defined(__linux__)
#   include <dlfcn.h>
#endif

DLL_EXPORT int luaopen_lupafromlua(lua_State* L)
{
#if defined(__linux__)
#   define STR(s) #s
#   define PYLIB_STR(s) STR(s)
#   if !defined(PYTHON_LIBRT)
#      error PYTHON_LIBRT must be defined when building under Linux!
#   endif
	/* Links to Python runtime library */
	if (dlopen(PYLIB_STR(PYTHON_LIBRT), RTLD_NOW | RTLD_GLOBAL) == NULL)
		return luaL_error(L, "Could not link to Python runtime library\n");
#endif

	/* Initialize Python without signal handlers */
	Py_InitializeEx(0);

	/* Check if Python was initialized successfully */
	if (!Py_IsInitialized())
		return luaL_error(L, "Could not initialize Python");
	
	/* Imports lupa */
	PyObject* lupa = PyImport_ImportModule("lupa");	
	if (lupa == NULL) {
		Py_Finalize();
		return luaL_error(L, "Could not import lupa");
	}

	/* Finalize Python */
	Py_Finalize();

	return 0;
}
