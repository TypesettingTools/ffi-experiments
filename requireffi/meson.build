requireffi_moon = files(
    'requireffi.moon'
)

requireffi_lua = custom_target('requireffiLua',
    output: ['requireffi.lua'],
    input: [requireffi_moon],
    command: lua_builder_command,
    build_by_default: moonc.found()
)
