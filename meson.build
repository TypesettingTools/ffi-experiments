project('ffi-experiments', 'c', 'cpp',
    license: 'ISC',
    meson_version: '>=0.49.0',
    default_options: ['c_std=c99', 'cpp_std=c++14', 'buildtype=release', 'b_ndebug=if-release']
)

deps = []
inc_dirs = []

static_deps = get_option('static_deps')
libcurl_path = get_option('libcurl_path')

cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')

if host_machine.system() == 'windows' or static_deps == 'true'
    add_project_arguments('-DCURL_STATICLIB', language: ['cpp'])
endif

if cc.get_argument_syntax() == 'gcc'
    cflags = ['-Wunreachable-code', '-Wfloat-equal', '-Wredundant-decls', '-Winit-self', '-Wpedantic']
    add_project_arguments(cc.get_supported_arguments(cflags), language: ['c', 'cpp'])
endif

if host_machine.system() == 'windows' and libcurl_path != ''
    deps += cxx.find_library('libcurl', dirs: join_paths(libcurl_path, 'lib'))
    inc_dirs += include_directories(join_paths(libcurl_path, 'include'))
    deps += cxx.find_library('crypt32')
    deps += cxx.find_library('normaliz')
    deps += cxx.find_library('wininet')
    deps += cxx.find_library('wldap32')
    deps += cxx.find_library('ws2_32')
else
    deps += dependency('libcurl', static: static_deps)
endif

if host_machine.system() == 'darwin'
    deps += dependency('appleframeworks', modules: ['CoreFoundation', 'SystemConfiguration'])
endif

if host_machine.system() == 'linux'
    deps += dependency('threads', static: static_deps)
endif

lua_builder = find_program('BuildLua.sh')

subdir('bad-mutex')
subdir('precise-timer')
subdir('download-manager')
subdir('requireffi')
