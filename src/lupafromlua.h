#ifndef LUPAFROMLUA_H
#define LUPAFROMLUA_H

#include <stdarg.h>
#include <stdlib.h>
#include <wchar.h>
#include <assert.h>

#include "lauxlib.h"
#include "Python.h"

#if defined(__linux__)
#	include <dlfcn.h>
#endif

#if defined(_MSC_VER)
#	define DLL_EXPORT __declspec(dllexport)
#	define DLL_IMPORT __declspec(dllimport)
#elif defined(__GNUC__)
#	define DLL_EXPORT __attribute__((visibility("default")))
#	define DLL_IMPORT
#else
#	define DLL_EXPORT
#	define DLL_IMPORT
#	error Unknown dynamic link import/export semantics.
#endif

#if LUA_VERSION_NUM >= 504
#	define read_lua_version(L)  ((long int) lua_version(L))
#elif LUA_VERSION_NUM >= 502
#	define read_lua_version(L)  ((long int) *lua_version(L))
#elif LUA_VERSION_NUM >= 501
#	define read_lua_version(L)  ((long int) LUA_VERSION_NUM)
#else
#	error Lupafromlua requires at least Lua 5.1
#endif

#if PY_MAJOR_VERSION >= 3
#	define IS_PY3K
#endif

#endif
