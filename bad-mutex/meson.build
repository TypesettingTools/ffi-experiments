bad_mutex_src = files(
    'BadMutex.cpp',
    'BadMutexC.cpp'
)

bad_mutex_moon = files(
    'BadMutex.moon'
)

bad_mutex = shared_library('BadMutex', bad_mutex_src)

bad_mutex_lua = custom_target('BadMutexLua',
    output: ['BadMutex.lua'],
    input: [bad_mutex_moon],
    command: lua_builder_command,
    build_by_default: moonc.found()
)
