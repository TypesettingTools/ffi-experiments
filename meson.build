project('ffi-experiments', 'c', 'cpp',
    license: 'ISC',
    meson_version: '>=0.41.0',
    default_options: ['c_std=c99', 'cpp_std=c++11']
)

cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')
cflags = ['-Wunreachable-code', '-Wfloat-equal', '-Wredundant-decls', '-Winit-self', '-Wpedantic']
if host_machine.system() == 'windows'
    add_project_arguments('-DCURL_STATICLIB', language: ['cpp'])
else
    add_project_arguments(cflags, language: ['c', 'cpp'])
endif

static_deps = get_option('static_deps')
libcurl_path = get_option('libcurl_path')

deps = []
inc_dirs = []

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

subdir('bad-mutex')
subdir('precise-timer')
subdir('threaded-libcurl')
