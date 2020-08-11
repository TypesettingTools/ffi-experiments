bad_mutex_src = files(
    'BadMutex.cpp',
    'BadMutexC.cpp'
)

bad_mutex_moon = files(
    'BadMutex.moon'
)

bad_mutex = shared_library('BadMutex', bad_mutex_src)

if host_machine.system() != 'windows'
    bad_mutex_lua = custom_target('BadMutexLua',
        output: ['BadMutex.lua'],
        input: [bad_mutex_moon],
        command: [lua_builder, '@INPUT@', '@OUTPUT@'],
        build_by_default: true
    )
endif
