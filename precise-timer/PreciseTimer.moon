ffi = require "ffi"
ffi.cdef [[
___INCLUDE___
int usleep(unsigned int);
void Sleep(unsigned long);
]]

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

class PreciseTimer
	@version = 0x000103
	@version_string = "0.1.3"

	PT = nil
	PTVersion = 0x000100

	freeTimer = ( timer ) ->
		PT.freeTimer timer

	new: ( additionalPaths = { } ) =>
		unless "table" == type additionalPaths
			additionalPaths = { tostring additionalPaths }

		libraryPaths = packagePaths "PT", @@__name
		for path in *additionalPaths
			table.insert libraryPaths, path

		unless PT
			messages = { "Could not load #{@@__name} C library." }
			success = false
			for path in *libraryPaths
				success, PT = pcall ffi.load, path
				if success
					@loadedLibraryPath = path
					break
				else
					table.insert messages, "Error loading %q: %s"\format path, PT\gsub "[\n\t\r]", " "

			assert success, table.concat messages, "\n"

			libVer = PT.version!
			if libVer < PTVersion or math.floor(libVer/65536%256) > math.floor(PTVersion/65536%256)
				error "Library version mismatch. Wanted #{PTVersion}, got #{libVer}."

		@timer = ffi.gc PT.startTimer!, freeTimer

	timeElapsed: =>
		return PT.getDuration @timer

	sleep: ffi.os == "Windows" and (( ms = 100 ) -> ffi.C.Sleep ms) or (( ms = 100 ) -> ffi.C.usleep ms*1000)
