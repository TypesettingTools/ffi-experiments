ffi = require "ffi"
requireffi = require "requireffi.requireffi"
ffi.cdef [[
___INCLUDE___
int usleep(unsigned int);
void Sleep(unsigned long);
]]


PTVersion = 0x000100
PT, loadedLibraryPath = requireffi "PT.PreciseTimer.PreciseTimer"
libVer = PT.version!
if libVer < PTVersion or math.floor(libVer/65536%256) > math.floor(PTVersion/65536%256)
	error "Library version mismatch. Wanted #{PTVersion}, got #{libVer}."

class PreciseTimer
	@version = 0x000106
	@version_string = "0.1.6"
	@__depCtrlInit = ( DependencyControl ) ->
		@version = DependencyControl {
			name: "#{@__name}",
			version: @version_string,
			description: "Measure times down to the nanosecond. Except not really.",
			author: "torque",
			url: "https://github.com/TypesettingTools/ffi-experiments",
			moduleName: "PT.#{@__name}",
			feed: "https://raw.githubusercontent.com/TypesettingTools/ffi-experiments/master/DependencyControl.json",
		}
	:loadedLibraryPath

	freeTimer = ( timer ) ->
		PT.freeTimer timer

	new: =>
		@timer = ffi.gc PT.startTimer!, freeTimer

	timeElapsed: =>
		return PT.getDuration @timer

	sleep: ffi.os == "Windows" and (( ms = 100 ) -> ffi.C.Sleep ms) or (( ms = 100 ) -> ffi.C.usleep ms*1000)
