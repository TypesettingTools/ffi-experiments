ffi = require "ffi"
ffi.cdef [[
___INCLUDE___
]]
local BM
__name = "BadMutex"
pathExt = "/automation/include/BM/#{(ffi.os != 'Windows') and 'lib' or ''}#{__name}.#{(OSX: 'dylib', Windows: 'dll')[ffi.os] or 'so'}"
libraryPaths = aegisub and {aegisub.decode_path( "?user"..pathExt ), aegisub.decode_path( "?data"..pathExt ), __name} or {__name}

success = false
for path in *libraryPaths
	success, BM = pcall ffi.load, path
	break if success

assert success, BM

return {
	lock: ->
		BM.lock!

	tryLock: ->
		return BM.try_lock!

	unlock: ->
		BM.unlock!
}
