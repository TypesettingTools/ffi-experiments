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

BMVersion = 0x000100
libVer = BM.version!
if libVer < BMVersion or math.floor(libVer/65536%256) > math.floor(BMVersion/65536%256)
	error "Library version mismatch. Wanted #{BMVersion}, got #{libVer}."

return {
	lock: ->
		BM.lock!

	tryLock: ->
		return BM.try_lock!

	unlock: ->
		BM.unlock!

	version: 0x000100
}
