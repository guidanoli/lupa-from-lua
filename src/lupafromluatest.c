#include <stdio.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

int main(int argc, char** argv)
{
	lua_State* L = luaL_newstate();
	luaL_openlibs(L);
	lua_getglobal(L, "debug");
	lua_getfield(L, -1, "traceback");
	lua_remove(L, -2);
	lua_getglobal(L, "require");
	lua_pushstring(L, "test");
	if (lua_pcall(L, 1, 1, 1))
	{
		fprintf(stderr, "%s: Could not import test script\n", argv[0]);
		if (lua_isstring(L, -1))
		{
			fprintf(stderr, "%s\n", lua_tostring(L, -1));
		}
		return 1;
	}
	lua_getfield(L, -1, "safe_run");
	lua_call(L, 0, 2);
	if (lua_isboolean(L, -2) && !lua_toboolean(L, -2))
	{
		fprintf(stderr, "%s: Test failed\n", argv[0]);
		if (lua_isstring(L, -1))
		{
			fprintf(stderr, "%s\n", lua_tostring(L, -1));
		}
		return 1;
	}
	lua_close(L);
	return 0;
}