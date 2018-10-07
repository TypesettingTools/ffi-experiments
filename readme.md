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

You will need: 
- A recent version of meson.
- A working c99 compiler.
- A working c++11 compiler.
- libcurl installed in some place your linker will think to look for it.

Building on OSX and Linux should be as simple as running the following:
```
cd /path/to/ffi-experiments
mason build --buildtype=release
cd build
ninja
```

Should you wish to statically link dependencies, simply include
`-Dstatic_deps=true` with the `mason build` command.

If you are on an operating system managed by a hulking corporate
abomination, things are a little bit more complicated. The following
instructions are for building with a recent version of Visual Studio.

You'll need a directory containing two subdirectories, `include` and
`lib`, containing the header files and a statically built libcurl
respectively. libcurl should be built with the same settings you intend
to use for DownloadManager.

Launch the relevant VS native tools command prompt. Be sure that if you
want a 64-bit built, you're using the one labeled x64. Then run the
following:
```
powershell
cd C:\Path\To\ffi-experiments
meson -Dlibcurl_path="C:\Path\To\libcurl" build --backend=vs --buildtype=release
```

You can then launch the solution, pick a god and pray, and then attempt
to build the three projects.

The companion lua scripts are not built by default and must be built
separately with the included `BuildLua.sh`. This is because they aren't
platform dependent, so you can just 
[download the release versions][binary] like everyone else. Also, in 
order to build them, you must have:

- bash or some bash-compatible shell.
- `moonc`, the moonscript compiler.
- Some variant of perl 5.
- The C preprocessor, `cpp`.

in addition to some of the earlier requirements.

[binary]: ../../releases/tag/r3
