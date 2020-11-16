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
	PyObject *lupa = NULL,
		 *lua_runtime_class = NULL,
		 *lua_state_capsule = NULL,
		 *constructor_args = NULL,
		 *constructor_kwargs = NULL,
		 *lua_runtime_obj = NULL;

#if PY_MAJOR_VERSION >= 3
	wchar_t *argv[] = {L"<lua>", 0};
#else
	char *argv[] = {"<lua>", 0};
#endif
	/* Set program name */
	Py_SetProgramName(argv[0]);

#if defined(__linux__)
#   define STR(s) #s
#   define PYLIB_STR(s) STR(s)
#   if !defined(PYTHON_LIBRT)
#      error PYTHON_LIBRT must be defined when building under Linux!
#   endif
	/* Links to Python runtime library */
	if (dlopen(PYLIB_STR(PYTHON_LIBRT), RTLD_NOW | RTLD_GLOBAL) == NULL) {
		lua_pushliteral(L, "Could not link to Python runtime library");
		goto luaerr;
	}
#endif

	/* Initialize Python without signal handlers */
	Py_InitializeEx(0);

	/* Check if Python was initialized successfully */
	if (!Py_IsInitialized()) {
		lua_pushliteral(L, "Could not initialize Python");
		goto finalize;
	}

	/* Set sys.argv variable */
	PySys_SetArgv(1, argv);
	
	/* Imports lupa */
	lupa = PyImport_ImportModule("lupa");	
	if (lupa == NULL) {
		lua_pushliteral(L, "Could not import lupa");
		goto deallocate;
	}

	/* Get lupa.LuaRuntime */
	lua_runtime_class = PyObject_GetAttrString(lupa, "LuaRuntime");
	if (lua_runtime_class == NULL) {
		lua_pushliteral(L, "Could not get LuaRuntime from lupa");
		goto deallocate;
	}

	/* Encapsule lua state */
	lua_state_capsule = PyCapsule_New(L, "lua_State", NULL);
	if (lua_state_capsule == NULL) {
		lua_pushliteral(L, "Could not create capsule for Lua state");
		goto deallocate;
	}

	/* Construct empty tuple */
	constructor_args = PyTuple_New(0);
	if (constructor_args == NULL) {
		lua_pushliteral(L, "Could not allocate tuple");
		goto deallocate;
	}

	/* Construct dictionary */
	constructor_kwargs = Py_BuildValue("{s:O}", "state", lua_state_capsule);
	if (constructor_kwargs == NULL) {
		lua_pushliteral(L, "Could not allocate dict");
		goto deallocate;
	}

	/* Call lupa.LuaRuntime constructor */
	lua_runtime_obj = PyObject_Call(lua_runtime_class, constructor_args, constructor_kwargs);
	if (lua_runtime_obj == NULL) {
		lua_pushliteral(L, "Could not create LuaRuntime object");
		goto deallocate;
	}

	return 0;

	/* In case of failure, deallocate in reverse order */
deallocate:
	Py_XDECREF(lua_runtime_obj);
	Py_XDECREF(constructor_kwargs);
	Py_XDECREF(constructor_args);
	Py_XDECREF(lua_state_capsule);
	Py_XDECREF(lua_runtime_class);
	Py_XDECREF(lupa);
finalize:
	Py_Finalize();
luaerr:
	return lua_error(L);
}
