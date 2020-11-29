add_library(lupafromlua SHARED lupafromlua.c)

set_target_properties(
	lupafromlua
	PROPERTIES
	PREFIX ""
	OUTPUT_NAME lupafromlua
	LINKER_LANGUAGE C
	LIBRARY_OUTPUT_DIRECTORY ${PROJECT_SOURCE_DIR})

target_include_directories(lupafromlua PUBLIC
	${LUA_INCLUDE_DIR} ${Python_INCLUDE_DIRS} ${CMAKE_CURRENT_SOURCE_DIR})

if(UNIX)
	get_filename_component(PYTHON_LIBRT ${Python_LIBRARIES} NAME)
	target_compile_definitions(lupafromlua PRIVATE "PYTHON_LIBRT=${PYTHON_LIBRT}")
endif()

if(WIN32)
	target_link_libraries(lupafromlua ${Python_LIBRARIES} ${LUA_LIBRARIES})
else()
	target_link_libraries(lupafromlua ${Python_LIBRARIES})
endif()