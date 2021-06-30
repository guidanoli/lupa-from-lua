# Lupa from lua library

add_library(lupafromlua SHARED lupafromlua.c)

set_target_properties(
	lupafromlua
	PROPERTIES
	PREFIX ""
	OUTPUT_NAME lupafromlua
	LINKER_LANGUAGE C)

target_include_directories(lupafromlua PUBLIC
	"${LUA_INCLUDE_DIR}" ${Python_INCLUDE_DIRS} "${CMAKE_CURRENT_SOURCE_DIR}")

if(UNIX)
	get_filename_component(PYTHON_LIBRT ${Python_LIBRARIES} NAME)
	target_compile_definitions(lupafromlua PRIVATE "PYTHON_LIBRT=${PYTHON_LIBRT}")
endif()

if(WIN32)
	target_link_libraries(lupafromlua ${Python_LIBRARIES} ${LUA_LIBRARIES})
else()
	target_link_libraries(lupafromlua ${Python_LIBRARIES})
endif()

# Lupa from lua test driver

add_executable(lupafromluatest lupafromluatest.c)
target_include_directories(lupafromluatest PRIVATE "${LUA_INCLUDE_DIR}")
target_link_libraries(lupafromluatest ${LUA_LIBRARIES})

# Copy Lua DLL if on Windows and if it exists

if(WIN32)
	foreach(LUA_LIBRARY ${LUA_LIBRARIES})
		get_filename_component(LUA_LIBRARY_DIR ${LUA_LIBRARY} DIRECTORY)
		get_filename_component(LUA_LIBRARY_NAME ${LUA_LIBRARY} NAME_WE)
		set(LUA_LIBRARY_DLL "${LUA_LIBRARY_DIR}/${LUA_LIBRARY_NAME}.dll")
		if((LUA_LIBRARY_NAME MATCHES lua) AND (EXISTS "${LUA_LIBRARY_DLL}"))
			add_custom_command(TARGET lupafromlua POST_BUILD
				COMMAND "${CMAKE_COMMAND}" -E copy
					"${LUA_LIBRARY_DLL}"
					"${LUPAFROMLUA_PROJECT_DIR}")
			break()
		endif()
	endforeach()
endif()

# Copy binaries to the root directory

add_custom_command(TARGET lupafromlua POST_BUILD
	COMMAND "${CMAKE_COMMAND}" -E copy
		"$<TARGET_FILE:lupafromlua>"
		"$<TARGET_FILE:lupafromluatest>"
		"${LUPAFROMLUA_PROJECT_DIR}")
