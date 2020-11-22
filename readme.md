#### FFI Experiments

C++ + luajit FFI = horrible cross-platform messes.

#### BadMutex

A global mutex.

#### PreciseTimer

Measure times down to the nanosecond. Except not really.

#### DownloadManager

Download things with libcurl without blocking Lua.

#### requireffi

Load C libraries using `package.path`.

#### Building

The preferred build system is [meson][meson], but a basic makefile is
also provided for those who do not wish to install it.

You will need:
- A recent version of meson.
- A working c99 compiler.
- A working c++11 compiler.
- Either libcurl installed in some place meson/your linker will think to look for it or, on Windows and OSX, a working CMake installation.

Building on OSX and Linux should be as simple as running the following:
```
cd /path/to/ffi-experiments
meson build
meson compile -C build
```

If you are on Windows, you should do this from the relevant VS native tools command prompt.

Should you wish to statically link dependencies, simply include `-Ddefault_library=static` with the `meson build` command.

The companion lua scripts are not built by default, for two reasons. The
first reason is that the generated lua scripts are platform independent,
so you can just [download the release versions][binary] like everyone
else. The second reason is that the lua build process assumes it is
running in a Posix environment with the programs `bash`, `cpp`, `perl`,
`moonc`, and `true` all being available to the user. If in an
appropriate environment, the lua scripts can be generated by
additionally running `ninja lua` (if using meson) or `make lua` (if
using the makefile). These targets will not be available on Windows.

[meson]: http://mesonbuild.com
[binary]: ../../releases/tag/r3
