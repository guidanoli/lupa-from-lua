#include "lupafromlua.h"

/* Checks if a condition is true. If not, raises an error in Lua. */
static void check_true (lua_State *L, int condition, const char *fmt, ...)
{
	if (!condition) {
		va_list argp;
		va_start(argp, fmt);
		luaL_where(L, 1);
		lua_pushvfstring(L, fmt, argp);
		va_end(argp);
		lua_concat(L, 2);
		lua_error(L);
	}
}

/* key for userdata in the registry that, when garbage collected, finalizes Python */
static const char * const LUPAFROMLUA = "LUPAFROMLUA";

/* __gc tag method for LUPAFROMLUA userdata: finalizes Python */
static int lupafromlua_gc (lua_State *L)
{
	void *handle = lua_touserdata(L, lua_upvalueindex(1));

	/* Finalizes Python */
	if (Py_IsInitialized())
		Py_Finalize();

#if defined(__linux__)
	if (handle != NULL) {
		/* Unlinks from Python runtime library */
		check_true(L, dlclose(handle) == 0,
				"Could not unlink from Python runtime library");
	}
#endif

	return 0;
}

/* Portable alternative for converting Python integers to C longs */
static long pyint_to_long (lua_State *L, PyObject *o, const char *oname)
{
	long l;

#ifdef IS_PY3K
#define PYINT_(x) PyLong_ ## x
#else
#define PYINT_(x) PyInt_ ## x
#endif

	check_true(L, PYINT_(Check)(o),
			"Expected %s type to be %s. Obtained: %s",
			oname, PYINT_(Type).tp_name, o->ob_type->tp_name);

	l = PYINT_(AsLong)(o);

	check_true(L, !(l == -1 && PyErr_Occurred()),
			"Could not convert %s to a long", oname);

#undef PYINT_

	return l;
}

DLL_EXPORT int luaopen_lupafromlua (lua_State *L)
{
	PyObject *lupa = NULL,
		*lupa_lua_version = NULL,
		*lupa_lua_version_major = NULL,
		*lupa_lua_version_minor = NULL,
		*lupa_lua_runtime_class = NULL,
		*py_capsule = NULL,
		*constructor_args = NULL,
		*constructor_kwargs = NULL,
		*lupa_lua_runtime_instance = NULL,
		*main_module = NULL;

	long current_lua_version = read_lua_version(L),
		current_lua_version_major = current_lua_version / 100,
		current_lua_version_minor = current_lua_version % 100,
		lupa_lua_version_major_l,
		lupa_lua_version_minor_l;

	int ltype;

	Py_ssize_t lupa_lua_version_len;

	void *handle = NULL;

#ifdef IS_PY3K
	wchar_t *argv[] = {L"<lua>", 0};
#else
	char *argv[] = {"<lua>", 0};
#endif
	/* Set program name */
	Py_SetProgramName(argv[0]);

#if defined(__linux__)
#	if defined(PYTHON_LIBRT)
#		define STR(s) #s
#		define XSTR(s) STR(s)

	/* Links to Python runtime library */
	check_true(L, (handle = dlopen(XSTR(PYTHON_LIBRT), RTLD_NOW | RTLD_GLOBAL)) != NULL,
			"Could not link to Python runtime library (\"" XSTR(PYTHON_LIBRT) "\")");

#		undef XSTR
#		undef STR
#	else
#		error PYTHON_LIBRT must be defined when building under Linux!
#	endif
#endif

	/* Get LUPAFROMLUA from registry */
	lua_getfield(L, LUA_REGISTRYINDEX, LUPAFROMLUA);

	/* Check if LUPAFROMLUA doesn't exist yet */
	if (!lua_isuserdata(L, -1)) {
		/* Create LUPAFROMLUA and add it to the registry */
		lua_pop(L, 1);
		lua_newuserdata(L, 0);
		lua_pushvalue(L, -1);
		lua_setfield(L, LUA_REGISTRYINDEX, LUPAFROMLUA);

		/* Create metatable for LUPAFROMLUA */
		lua_createtable(L, 0, 1);
		lua_pushlightuserdata(L, handle);
		lua_pushcclosure(L, lupafromlua_gc, 1);

		/* Set finalizer for LUPAFROMLUA */
		lua_setfield(L, -2, "__gc");
		lua_setmetatable(L, -2);
	}

	/* Initialize Python without signal handlers */
	Py_InitializeEx(0);

	/* Check if Python was initialized successfully */
	check_true(L, Py_IsInitialized(),
			"Could not initialize Python");

	/* Set sys.argv variable */
	PySys_SetArgv(1, argv);

	/* Imports the lupa module
	
	   import lupa */
	check_true(L, (lupa = PyImport_ImportModule("lupa")) != NULL,
			"Could not import lupa");

	/* Get LUA_VERSION from lupa
	
	   = lupa.LUA_VERSION */
	check_true(L, (lupa_lua_version = PyObject_GetAttrString(lupa, "LUA_VERSION")) != NULL,
			"Could not get LUA_VERSION from lupa");

	/* Make sure lupa.LUA_VERSION is a tuple
	
	   = type(lupa.LUA_VERSION) is tuple */
	check_true(L, PyTuple_Check(lupa_lua_version),
			"Expected lupa.LUA_VERSION type to be tuple. Obtained: %s", lupa_lua_version->ob_type->tp_name);

	/* Get lua.LUA_VERSION length
	
	   = len(lupa.LUA_VERSION) */
	lupa_lua_version_len = PyTuple_GET_SIZE(lupa_lua_version);

	/* Make sure lupa.LUA_VERSION has at least 2 items
	
	   = len(lupa.LUA_VERSION) >= 2 */
	check_true(L, lupa_lua_version_len >= 2,
			"Expected lupa.LUA_VERSION length to be of at least 2. Obtained: %d", (int) lupa_lua_version_len);

	/* Get first object from lupa.LUA_VERSION
	
	   = lupa.LUA_VERSION[0] */
	check_true(L, (lupa_lua_version_major = PyTuple_GetItem(lupa_lua_version, 0)) != NULL,
			"Could not get lupa.LUA_VERSION[0]");

	/* Convert lupa.LUA_VERSION[0] to a C long */
	lupa_lua_version_major_l = pyint_to_long(L, lupa_lua_version_major, "lupa.LUA_VERSION[0]");

	/* Get second object from lupa.LUA_VERSION
	
	   = lupa.LUA_VERSION[1] */
	check_true(L, (lupa_lua_version_minor = PyTuple_GetItem(lupa_lua_version, 1)) != NULL,
			"Could not get lupa.LUA_VERSION[1]");

	/* Convert lupa.LUA_VERSION[1] to a C long */
	lupa_lua_version_minor_l = pyint_to_long(L, lupa_lua_version_minor, "lupa.LUA_VERSION[1]");

	Py_DECREF(lupa_lua_version);

	/* Make sure Lupa is built the same version of Lua as the state L */
	check_true(L, lupa_lua_version_major_l == current_lua_version_major &&
			lupa_lua_version_minor_l == current_lua_version_minor,
			"Expected Lua version built into Lupa to be %d.%d. Obtained: %d.%d",
			(int) current_lua_version_major, (int) current_lua_version_minor,
			(int) lupa_lua_version_major_l, (int) lupa_lua_version_minor_l);

	/* Get LuaRuntime from lupa
	
	   = lupa.LuaRuntime */
	check_true(L, (lupa_lua_runtime_class = PyObject_GetAttrString(lupa, "LuaRuntime")) != NULL,
			"Could not get LuaRuntime from the lupa module");

	Py_DECREF(lupa);

	/* Encapsulate the Lua state with the label "lua_State"
	
	   (this step cannot be recreated in Python) */
	check_true(L, (py_capsule = PyCapsule_New(L, "lua_State", NULL)) != NULL,
			"Could not create capsule for Lua state");

	/* Construct an empty tuple
	
	   = tuple() */
	check_true(L, (constructor_args = PyTuple_New(0)) != NULL,
			"Could not allocate tuple");

	/* Construct a dictionary
	
	   = dict(state=<py_capsule>) */
	check_true(L, (constructor_kwargs = Py_BuildValue("{s:O}", "state", py_capsule)) != NULL,
			"Could not allocate dict");

	Py_DECREF(py_capsule);

	/* Call the lupa.LuaRuntime constructor
	
	   = lupa.LuaRuntime(*constructor_args, **constructor_kwargs) */
	check_true(L, (lupa_lua_runtime_instance = PyObject_Call(lupa_lua_runtime_class, constructor_args, constructor_kwargs)) != NULL,
			"Could not create LuaRuntime object");

	Py_DECREF(lupa_lua_runtime_class);
	Py_DECREF(constructor_args);
	Py_DECREF(constructor_kwargs);

	/* Checks if there is an object on top of the stack */
	check_true(L, lua_gettop(L) >= 1,
			"Expected object to be on top of the stack, but it is empty");
 
	/* Get the type of the object on top of the stack */
	ltype = lua_type(L, -1);

	/* Checks that the module table is on top of stack */
	check_true(L, ltype == LUA_TTABLE,
			"Expected table on top of the stack. Obtained: %s", lua_typename(L, ltype));

	/* Get the Python main module
	
	   import __main__ */
	check_true(L, (main_module = PyImport_AddModule("__main__")) != NULL,
			"Could not add Python __main__ module");

	/* Set LuaRuntime as lua in the Python main module global scope
	
	   __main__.lua = <lupa_lua_runtime_instance> */
	check_true(L, PyObject_SetAttrString(main_module, "lua", lupa_lua_runtime_instance) == 0,
			"Could not set LuaRuntime object in the global scope as 'lua'");

	Py_DECREF(lupa_lua_runtime_instance);

	return 1;
}
