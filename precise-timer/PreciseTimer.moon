local PT, PreciseTimer

haveFFI, ffi = pcall require, "ffi"
if haveFFI
	haveFFI, PT = pcall ffi.load, "PreciseTimer"

unless haveFFI
	class PreciseTimer
		new: =>
			@startTime = os.time!

		timeElapsed: =>
			return os.time! - @startTime

else
	ffi.cdef [[
		___INCLUDE___
	]]

	class PreciseTimer
		freeTimer = ( timer ) ->
			PT.freeTimer timer

		new: =>
			@timer = ffi.gc PT.startTimer!, freeTimer

		timeElapsed: =>
			return PT.getDuration @timer

-- ffi.cdef "int usleep( unsigned int usec );"

-- timer = PreciseTimer!
-- ffi.C.usleep 100000
-- print tostring timer\timeElapsed!
