add_library(lupafromlua SHARED lupafromlua.c)

set_target_properties(
	lupafromlua
	PROPERTIES
	PREFIX ""
	OUTPUT_NAME lupafromlua
	LINKER_LANGUAGE C)

target_include_directories(lupafromlua PUBLIC ${LUA_INCLUDE_DIR} ${PYTHON_INCLUDE_DIRS})

if(UNIX)
	get_filename_component(PYTHON_LIBRT ${PYTHON_LIBRARIES} NAME)
	target_compile_definitions(lupafromlua PRIVATE PYTHON_LIBRT=${PYTHON_LIBRT})
endif(UNIX)

if(WIN32)
	target_link_libraries(lupafromlua ${PYTHON_LIBRARIES} ${LUA_LIBRARIES})
else()
	target_link_libraries(lupafromlua ${PYTHON_LIBRARIES})
endif()

add_custom_command(TARGET lupafromlua POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E make_directory
		"${PROJECT_SOURCE_DIR}/lib")

add_custom_command(TARGET lupafromlua POST_BUILD
	COMMAND ${CMAKE_COMMAND} -E copy
		"$<TARGET_FILE:lupafromlua>"
		"${PROJECT_SOURCE_DIR}/lib")
