requireffi_moon = files(
    'requireffi.moon'
)

if host_machine.system() != 'windows'
    requireffi_lua = custom_target('requireffiLua',
        output: ['requireffi.lua'],
        input: [requireffi_moon],
        command: [lua_builder, '@INPUT@', '@OUTPUT@']
    )
endif
