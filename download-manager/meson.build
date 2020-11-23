download_manager_src = files(
    'Downloader.cpp',
    'DownloadManager.cpp',
    'DownloadManagerC.cpp',
    'sha1.c'
)

download_manager_moon = files(
    'DownloadManager.moon'
)

download_manager = shared_library('DownloadManager', download_manager_src, dependencies: deps)

download_manager_lua = custom_target('DownloadManagerLua',
    output: ['DownloadManager.lua'],
    input: [download_manager_moon],
    command: lua_builder_command,
    build_by_default: moonc.found()
)
