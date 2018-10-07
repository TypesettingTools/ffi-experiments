precise_timer_src = files(
    'PreciseTimer.cpp',
    'PreciseTimerC.cpp'
)

precise_timer_moon = files(
    'PreciseTimer.moon'
)

precise_timer = shared_library('PreciseTimer', precise_timer_src)

if host_machine.system() != 'windows'
    precise_timer_lua = custom_target('PreciseTimerLua',
        output: ['PreciseTimer.lua'],
        input: [precise_timer_moon],
        command: [lua_builder, '@INPUT@', '@OUTPUT@']
    )
endif
