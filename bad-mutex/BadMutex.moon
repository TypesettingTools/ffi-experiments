ffi = require "ffi"
requireffi = require "requireffi.requireffi"
ffi.cdef [[
___INCLUDE___
]]

BM, loadedLibraryPath = requireffi "BM.BadMutex"
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

	version: 0x000102
	:loadedLibraryPath
}
