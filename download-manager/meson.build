download_manager_src = files(
    'Downloader.cpp',
    'DownloadManager.cpp',
    'DownloadManagerC.cpp',
    'sha1.c'
)

download_manager_moon = files(
    'DownloadManager.moon'
)

download_manager = shared_library('DownloadManager', download_manager_src, dependencies: deps, include_directories: inc_dirs)

if host_machine.system() != 'windows'
    download_manager_lua = custom_target('DownloadManagerLua',
        output: ['DownloadManager.lua'],
        input: [download_manager_moon],
        command: [lua_builder, '@INPUT@', '@OUTPUT@'],
        build_by_default: true
    )
endif
