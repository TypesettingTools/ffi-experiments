project('ffi-experiments', 'c', 'cpp',
    license: 'ISC',
    meson_version: '>=0.55.0',
    default_options: ['c_std=c99', 'cpp_std=c++14', 'warning_level=2', 'buildtype=release', 'b_ndebug=if-release'],
)

cmake = import('cmake')

deps = []

cc = meson.get_compiler('c')
cxx = meson.get_compiler('cpp')

host_win_or_osx = host_machine.system() == 'windows' or host_machine.system() == 'darwin'

libcurl_dep = dependency('', required: false)
if get_option('default_library') == 'static' and host_win_or_osx
    add_project_arguments('-DCURL_STATICLIB', language: ['cpp'])
else
    libcurl_dep = dependency('libcurl', required: not host_win_or_osx)
endif

if libcurl_dep.found()
    deps += libcurl_dep
else
    curl_options = cmake.subproject_options()

    if host_machine.system() == 'windows'
        curl_options.add_cmake_defines({'CURL_TARGET_WINDOWS_VERSION': '0x601', 'CMAKE_USE_SCHANNEL': true})
    elif host_machine.system() == 'darwin'
        curl_options.add_cmake_defines({'CMAKE_USE_SECTRANSP': true})
    endif
    curl_options.add_cmake_defines({'BUILD_SHARED_LIBS': false,
                                    'CMAKE_BUILD_TYPE': 'Release',
                                    'BUILD_CURL_EXE': false,
                                    'HTTP_ONLY': true})

    curl = cmake.subproject('curl', options: curl_options)

    deps += curl.dependency('libcurl')
endif

if host_machine.system() == 'windows'
    deps += cxx.find_library('crypt32')
    deps += cxx.find_library('normaliz')
    deps += cxx.find_library('wininet')
    deps += cxx.find_library('wldap32')
    deps += cxx.find_library('ws2_32')
endif

if host_machine.system() == 'darwin'
    deps += dependency('appleframeworks', modules: ['CoreFoundation', 'SystemConfiguration'])
endif

if host_machine.system() == 'linux'
    deps += dependency('threads')
endif

lua_builder = find_program('build_lua.py')
moonc = find_program('moonc', required: false)
lua_builder_command = [lua_builder, '@INPUT@', '@OUTPUT@']
if moonc.found()
    lua_builder_command += ['--moonc', moonc]
else
    warning('moonc not found, building only the native components')
endif

subdir('bad-mutex')
subdir('precise-timer')
subdir('download-manager')
subdir('requireffi')
