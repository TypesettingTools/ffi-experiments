ffi = require "ffi"
ffi.cdef [[
___INCLUDE___
]]
local BM, loadedLibraryPath
__name = "BadMutex"
packagePaths = ( namespace, libraryName ) ->
	paths = { }
	fixedLibraryName = namespace .. "/" .. "#{(ffi.os != 'Windows') and 'lib' or ''}#{libraryName}.#{(OSX: 'dylib', Windows: 'dll')[ffi.os] or 'so'}"
	package.path\gsub "([^;]+)", ( path ) ->
		-- the init.lua paths are just dupes of other paths.
		if path\match "/%?/init%.lua$"
			return

		path = path\gsub "//?%?%.lua$", "/"
		table.insert paths, path .. fixedLibraryName

	-- Add the untouched library name so that ffi will search system
	-- library paths too.
	table.insert paths, libraryName
	return paths

libraryPaths = packagePaths "BM", __name

messages = { "Could not load #{__name} C library." }
success = false
for path in *libraryPaths
	success, BM = pcall ffi.load, path
	if success
		loadedLibraryPath = path
		break
	else
		table.insert messages, "Error loading %q: %s"\format path, BM\gsub "[\n\t\r]", " "

assert success, table.concat messages, "\n"

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

	version: 0x000101
	:loadedLibraryPath
}
