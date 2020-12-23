#include "lupafromlua.h"

#include <stdlib.h>
#include <wchar.h>

#include "Python.h"
#include "lauxlib.h"

#if defined(__linux__)
#	include <dlfcn.h>
#endif

/* Checks if a condition is true. If not, raises an error in Lua. */
#define check_true(condition, error_message) \
do { \
	if (!(condition)) { \
		lupafromlua_gc(L); \
		return luaL_error(L, error_message); \
	} \
} while(0)

/* key for table in the registry that when garbage collected finalizes Python */
static const char* const LUPAFROMLUA = "_LUPAFROMLUA";

/* __gc tag method for LUPAFROMLUA table: finalizes Python */
static int lupafromlua_gc(lua_State *L)
{
	if (Py_IsInitialized())
		Py_Finalize();

	return 0;
}

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
	check_true(dlopen(PYLIB_STR(PYTHON_LIBRT), RTLD_NOW | RTLD_GLOBAL),
			"Could not link to Python runtime library");

#	else
#		error PYTHON_LIBRT must be defined when building under Linux!
#	endif
#endif

	/* Create LUPAFROMLUA table */
	luaL_getsubtable(L, LUA_REGISTRYINDEX, LUPAFROMLUA);

	/* Create metatable for LUPAFROMLUA */
	lua_createtable(L, 0, 1);
	lua_pushcfunction(L, lupafromlua_gc);

	/* Set finalizer for LUPAFROMLUA table */
	lua_setfield(L, -2, "__gc");
	lua_setmetatable(L, -2);

	/* Initialize Python without signal handlers */
	Py_InitializeEx(0);

	/* Check if Python was initialized successfully */
	check_true(Py_IsInitialized(),
			"Could not initialize Python");

	/* Set sys.argv variable */
	PySys_SetArgv(1, argv);

	/* Imports the lupa module
	
	   import lupa */
	check_true(lupa = PyImport_ImportModule("lupa"),
			"Could not import lupa");

	/* Get LuaRuntime from lupa
	
	   = lupa.LuaRuntime */
	check_true(lua_runtime_class = PyObject_GetAttrString(lupa, "LuaRuntime"),
			"Could not get LuaRuntime from lupa");

	/* Encapsulate the Lua state with the label "lua_State"
	
	   (this step cannot be recreated in Python) */
	check_true(lua_state_capsule = PyCapsule_New(L, "lua_State", NULL),
			"Could not create capsule for Lua state");

	/* Construct an empty tuple
	
	   = tuple() */
	check_true(constructor_args = PyTuple_New(0),
			"Could not allocate tuple");

	/* Construct a dictionary
	
	   = dict(state=<lua_state_capsule>) */
	check_true(constructor_kwargs = Py_BuildValue("{s:O}", "state", lua_state_capsule),
			"Could not allocate dict");

	/* Call the lupa.LuaRuntime constructor
	
	   = lupa.LuaRuntime(*constructor_args, **constructor_kwargs) */
	check_true(lua_runtime_obj = PyObject_Call(lua_runtime_class, constructor_args, constructor_kwargs),
			"Could not create LuaRuntime object");

	/* Checks that the module table is on top of stack */
	check_true(lua_gettop(L) >= 1 && lua_type(L, -1) == LUA_TTABLE,
			"Missing table on top of Lua stack");

	/* Get the Python main module
	
	   import __main__ */
	check_true(main_module = PyImport_AddModule("__main__"),
			"Missing Python main module");

	/* Set LuaRuntime as lua in the Python main module global scope
	
	   __main__.lua = <lua_runtime_obj> */
	check_true(PyObject_SetAttrString(main_module, "lua", lua_runtime_obj) == 0,
			"Could not set LuaRuntime object in the global scope");

	return 1;
}
