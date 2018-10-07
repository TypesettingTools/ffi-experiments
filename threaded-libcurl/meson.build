download_manager_src = files(
    'Downloader.cpp',
    'DownloadManager.cpp',
    'DownloadManagerC.cpp',
    'sha1.c'
)

download_manager = shared_library('DownloadManager', download_manager_src, dependencies: deps, include_directories: inc_dirs)
