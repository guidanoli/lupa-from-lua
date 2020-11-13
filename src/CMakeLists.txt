add_library(lupafromlua SHARED lupafromlua.c)

target_include_directories(lupafromlua PUBLIC ${LUA_INCLUDE_DIR} ${PYTHON_INCLUDE_DIRS})

if(WIN32)
	target_link_libraries(lupafromlua ${PYTHON_LIBRARIES} ${LUA_LIBRARIES})
else()
	target_link_libraries(lupafromlua ${PYTHON_LIBRARIES})
endif()
