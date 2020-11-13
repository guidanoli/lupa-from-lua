#include "lupafromlua.h"
#include "Python.h"
#include "lua.h"

DLL_EXPORT int luaopen_lupafromlua(lua_State* L)
{
	/* Initialize Python without signal handlers */
	Py_InitializeEx(0);

	/* Check if Python was initialized successfully */
	if (!Py_IsInitialized()) {
		lua_pushliteral(L, "Could not initialize Python");
		lua_error(L);
		return 0;
	}
	
	if (PyRun_SimpleString("print(\"Hello World from Python\")") != 0) {
		lua_pushliteral(L, "Python raised an exception");
		lua_error(L);
		return 0;
	}

	/* Finalize Python */
	Py_Finalize();

	return 0;
}
