#include "lupafromlua.h"

#include <Python.h>
#include <lua.h>

#if defined(__linux__)
#   include <dlfcn.h>
#endif

DLL_EXPORT int luaopen_lupafromlua(lua_State* L)
{
#if defined(__linux__)
#   define STR(s) #s
#   define PYLIB_STR(s) STR(s)
#if !defined(PYTHON_LIBRT)
#   error PYTHON_LIBRT must be defined when building under Linux!
#endif
	/* Links to Python runtime library */
        void *ok = dlopen(PYLIB_STR(PYTHON_LIBRT), RTLD_NOW | RTLD_GLOBAL);
        assert(ok); (void) ok;
#endif

	/* Initialize Python without signal handlers */
	Py_InitializeEx(0);

	/* Check if Python was initialized successfully */
	if (!Py_IsInitialized()) {
		lua_pushliteral(L, "Could not initialize Python");
		lua_error(L);

		/* Don't go any further, because Python must be
		 * initialized in order to call any API function */
		return 0;
	}
	
	/* Imports lupa */
	PyObject* lupa = PyImport_ImportModule("lupa");	
	if (lupa == NULL) {
		Py_Finalize();
		lua_pushliteral(L, "Could not import lupa");
		lua_error(L);
	}

	/* Finalize Python */
	Py_Finalize();

	return 0;
}
