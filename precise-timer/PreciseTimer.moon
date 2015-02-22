ffi = require "ffi"
ffi.cdef [[
___INCLUDE___
int usleep(unsigned int);
void Sleep(unsigned long);
]]

class PreciseTimer
	PT = nil
	pathExt = "/automation/include/#{@__name}/#{@__name}.#{(OSX: 'dylib', Windows: 'dll')[ffi.os] or 'so'}"
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

			error PT unless success

		@timer = ffi.gc PT.startTimer!, freeTimer

	timeElapsed: =>
		return PT.getDuration @timer

	sleep: ffi.os == "Windows" and (( ms = 100 ) -> ffi.C.Sleep ms) or (( ms = 100 ) -> ffi.C.usleep ms*1000)
