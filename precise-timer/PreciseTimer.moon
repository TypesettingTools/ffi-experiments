PreciseTimer, PT = "PreciseTimer"

haveFFI, ffi = pcall require, "ffi"
if haveFFI
	if aegisub
		libPath= "/automation/include/#{PreciseTimer}/#{PreciseTimer}.#{(OSX: 'dylib', Windows: 'dll')[ffi.os] or 'so'}"
		haveFFI, PT = pcall ffi.load, aegisub.decode_path "?user"..libPath
		unless haveFFI
			haveFFI, PT = pcall ffi.load, aegisub.decode_path "?data"..libPath
	else
		haveFFI, PT = pcall ffi.load, PreciseTimer

unless haveFFI
	class PreciseTimer
		new: =>
			@startTime = os.time!

		timeElapsed: =>
			return os.time! - @startTime

else
	ffi.cdef [[
		___INCLUDE___
void Sleep(int ms);
int poll(struct pollfd *fds, unsigned long nfds, int timeout);
	]]

	class PreciseTimer
		freeTimer = ( timer ) ->
			PT.freeTimer timer

		new: =>
			@timer = ffi.gc PT.startTimer!, freeTimer

		timeElapsed: =>
			return PT.getDuration @timer

		sleep: ffi.os == "Windows" and ( (ms) => ffi.C.Sleep ms ) or ( (ms) => ffi.C.poll nil, 0, s*1000 )

-- ffi.cdef "int usleep( unsigned int usec );"

-- timer = PreciseTimer!
-- ffi.C.usleep 100000
-- print tostring timer\timeElapsed!
