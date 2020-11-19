#include "lupafromlua.h"

#include <stdlib.h>
#include <wchar.h>

#include "Python.h"
#include "lua.h"

#if defined(__linux__)
#	include <dlfcn.h>
#endif

DLL_EXPORT int luaopen_lupafromlua(lua_State *L)
{
	PyObject *lupa = NULL,
		*lua_runtime_class = NULL,
		*lua_state_capsule = NULL,
		*constructor_args = NULL,
		*constructor_kwargs = NULL,
		*lua_runtime_obj = NULL,
		*main_module = NULL;

#if PY_MAJOR_VERSION >= 3
	wchar_t *argv[] = {L"<lua>", 0};
#else
	char *argv[] = {"<lua>", 0};
#endif
	/* Set program name */
	Py_SetProgramName(argv[0]);

#if defined(__linux__)
#	if defined(PYTHON_LIBRT)
#		define STR(s) #s
#		define PYLIB_STR(s) STR(s)
	/* Links to Python runtime library */
	if (dlopen(PYLIB_STR(PYTHON_LIBRT), RTLD_NOW | RTLD_GLOBAL) == NULL) {
		lua_pushliteral(L, "Could not link to Python runtime library");
		goto luaerr;
	}
#	else
#		error PYTHON_LIBRT must be defined when building under Linux!
#	endif
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

	/* Imports the lupa module
	
	   import lupa */
	lupa = PyImport_ImportModule("lupa");
	if (lupa == NULL) {
		lua_pushliteral(L, "Could not import lupa");
		goto deallocate;
	}

	/* Get LuaRuntime from lupa
	
	   = lupa.LuaRuntime */
	lua_runtime_class = PyObject_GetAttrString(lupa, "LuaRuntime");
	if (lua_runtime_class == NULL) {
		lua_pushliteral(L, "Could not get LuaRuntime from lupa");
		goto deallocate;
	}

	/* Encapsulate the Lua state with the label "lua_State"
	
	   (this step cannot be recreated in Python) */
	lua_state_capsule = PyCapsule_New(L, "lua_State", NULL);
	if (lua_state_capsule == NULL) {
		lua_pushliteral(L, "Could not create capsule for Lua state");
		goto deallocate;
	}

	/* Construct an empty tuple
	
	   = tuple() */
	constructor_args = PyTuple_New(0);
	if (constructor_args == NULL) {
		lua_pushliteral(L, "Could not allocate tuple");
		goto deallocate;
	}

	/* Construct a dictionary
	
	   = dict(state=<lua_state_capsule>) */
	constructor_kwargs = Py_BuildValue("{s:O}", "state", lua_state_capsule);
	if (constructor_kwargs == NULL) {
		lua_pushliteral(L, "Could not allocate dict");
		goto deallocate;
	}

	/* Call the lupa.LuaRuntime constructor
	
	   = lupa.LuaRuntime(*constructor_args, **constructor_kwargs) */
	lua_runtime_obj = PyObject_Call(lua_runtime_class, constructor_args, constructor_kwargs);
	if (lua_runtime_obj == NULL) {
		lua_pushliteral(L, "Could not create LuaRuntime object");
		goto deallocate;
	}

	/* Checks that the module table is on top of stack */
	if (lua_gettop(L) < 1 || lua_type(L, -1) != LUA_TTABLE) {
		lua_pushliteral(L, "Missing table on top of Lua stack");
		goto deallocate;
	}

	/* Get the Python main module
	
	   import __main__ */
	main_module = PyImport_AddModule("__main__");
	if (main_module == NULL) {
		lua_pushliteral(L, "Missing Python main module");
		goto deallocate;
	}

	/* Set LuaRuntime as lua in the Python main module global scope
	
	   __main__.lua = <lua_runtime_obj> */
	if (PyObject_SetAttrString(main_module, "lua", lua_runtime_obj) < 0) {
		lua_pushliteral(L, "Could not set LuaRuntime object in the global scope");
		goto deallocate;
	}

	return 1;

deallocate:
	/* Deallocate the Python objects */
	Py_XDECREF(lua_runtime_obj);
	Py_XDECREF(constructor_kwargs);
	Py_XDECREF(constructor_args);
	Py_XDECREF(lua_state_capsule);
	Py_XDECREF(lua_runtime_class);
	Py_XDECREF(lupa);
finalize:
	/* Finalize Python */
	Py_Finalize();
luaerr:
	/* Raise an error in Lua */
	return lua_error(L);
}
