ffi = require "ffi"
ffi.cdef [[
___INCLUDE___
int usleep(unsigned int);
void Sleep(unsigned long);
]]

class PreciseTimer
	@version = 0x000102
	@version_string = "0.1.2"

	PT = nil
	PTVersion = 0x000100
	pathExt = "/automation/include/#{@__name}/#{(ffi.os != 'Windows') and 'lib' or ''}#{@__name}.#{(OSX: 'dylib', Windows: 'dll')[ffi.os] or 'so'}"
	defaultLibraryPaths = aegisub and {aegisub.decode_path( "?user"..pathExt ), aegisub.decode_path( "?data"..pathExt )} or {@__name}

	freeTimer = ( timer ) ->
		PT.freeTimer timer

	new: ( libraryPaths = defaultLibraryPaths ) =>
		unless PT
			libraryPaths = { libraryPaths } unless "table" == type libraryPaths
			success = false
			for path in *libraryPaths
				success, PT = pcall ffi.load, path
				break if success

			if success
				libVer = PT.version!
				if libVer < PTVersion or math.floor(libVer/65536%256) > math.floor(PTVersion/65536%256)
					error "Library version mismatch. Wanted #{PTVersion}, got #{libVer}."

			assert success, PT

		@timer = ffi.gc PT.startTimer!, freeTimer

	timeElapsed: =>
		return PT.getDuration @timer

	sleep: ffi.os == "Windows" and (( ms = 100 ) -> ffi.C.Sleep ms) or (( ms = 100 ) -> ffi.C.usleep ms*1000)
