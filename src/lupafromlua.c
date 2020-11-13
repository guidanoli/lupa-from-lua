#include "lupafromlua.h"
#include "lua.h"

DLL_EXPORT int luaopen_lupafromlua(lua_State* L)
{
	lua_pushliteral(L, "Hello, World!");
	return 1;
}
