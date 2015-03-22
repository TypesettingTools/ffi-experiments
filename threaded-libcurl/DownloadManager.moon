[[---------- Usage ----------

1. Create a DownloadManager:

	manager = DownloadManager!

	You can supply a single library search path or a table of search paths for the DownloadManager library.
	On Aegisub, this will default to the system and user DownloadManager module directories.
	Otherwise the default library search path will be used.

2. Add some downloads:

	manager\addDownload "https://a.real.website", "out3"

	If you have a SHA-1 hash to check the downloaded file against, use:
		manager\addDownload "https://a.real.website", "out2", "b52854d1f79de5ebeebf0160447a09c7a8c2cde4"

	You may want to keep a reference of your download to check its result later:
		myDownload = manager\addDownload "https://a.real.website", "out2",

	Downloads will start immediately. Do whatever you want here while downloads happen in the background.
	The output file must contain a full path and file name. There is no working directory and automatic file naming is unsupported.

3. Wait for downloads to finish:

	Call manager\waitForFinish(cb) to loop until remaining downloads finish.
	The progress callback can call manager\cancel! or manager\clear! to interrupt and break open connections.

	The current overall progress will be passed to the provided callback as a number in range 0-100:
		manager\waitForFinish ( progress ) ->
			print tostring progress

4. Check for download errors:

	Check a specific download:
		error dl.error if dl.error

	Print all failed downloads:
		for dl in *manager.failedDownloads
			print "Download ##{dl.id} error: #{dl.error}"

	Get a descriptive overall error message:
		error = table.concat ["#{dl.url}: #{dl.error}" for dl in *manager.failedDownloads], "\n"

5. Clear all downloads:

	manager\clear!

	Removes all downloads from the downloader and resets all counters.


Error Handling:
	Errors are handled in typical Lua fashion.
	DownloadManager will only throw an error in case the library failed to load.
	If any other error is encoutered the script will return nil along with an error message.

]]

havelfs, lfs = pcall require, "lfs"
ffi = require "ffi"
ffi.cdef [[
___INCLUDE___
int usleep(unsigned int);
void Sleep(unsigned long);
]]

sleep = ffi.os == "Windows" and (( ms = 100 ) -> ffi.C.Sleep ms) or (( ms = 100 ) -> ffi.C.usleep ms*1000)
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

class DownloadManager
	@version = 0x000107
	@version_string = "0.1.7"

	DM = nil
	DMVersion = 0x000103

	msgs = {
		notInitialized: "#{@__name} not initialized.",
		addMissingArgs: "Required arguments #1 (url) or #2 (outfile) had the wrong type. Expected string, got '%s' and '%s'.",
		checkMissingArgs: "Required arguments #1 (filename/string) and #2 (expected) or the wrong type. Expected string, got '%s' and '%s'.",
		outNoFullPath: "Argument #2 (outfile) must contain a full path (relative paths not supported), got %s.",
		outNoFile: "Argument #2 (outfile) must contain a full path with file name, got %s."
	}

	freeManager = ( manager ) ->
		DM.freeDM manager

	new: ( additionalPaths = { } ) =>
		unless "table" == type additionalPaths
			additionalPaths = { tostring additionalPaths }

		libraryPaths = packagePaths "DM", @@__name
		for path in *additionalPaths
			table.insert libraryPaths, path

		unless DM
			success = false
			for path in *libraryPaths
				success, DM = pcall ffi.load, path
				if success
					@loadedLibraryPath = path
					break

			if success
				libVer = DM.version!
				if libVer < DMVersion or math.floor(libVer/65536%256) > math.floor(DMVersion/65536%256)
					error "Library version mismatch. Wanted #{DMVersion}, got #{libVer}."

			assert success, "Could not load #{@@__name} C library."

		@manager = ffi.gc DM.newDM!, freeManager
		@downloads       = { }
		@downloadCount   = 0
		@failedDownloads = { }
		@failedCount     = 0

	addDownload: ( url, outfile, sha1 ) =>
		return nil, msgs.notInitialized unless DM

		urlType, outfileType = type(url), type(outfile)
		assert urlType=="string" and outfileType=="string", msgs.addMissingArgs\format urlType, outfileType

		-- expand leading ~ ourselves.
		if homeDir = os.getenv "HOME"
			outfile = outfile\gsub "^~", homeDir .. "/"

		dev, dir, file = outfile\match "^(#{ffi.os=='Windows' and '%a:[\\/]' or '/'})(.*)[/\\](.*)$"

		-- check that outfile is a full path as we don't support relative
		-- ones or automatic file naming
		if not dev or #dir < 1
			return nil, msgs.outNoFullPath\format outfile
		elseif #file < 1
			return nil, msgs.outNoFile\format outfile

		if havelfs
			-- check that directory exists, but only if we have lfs.
			dir = dev .. dir
			mode, err = lfs.attributes dir, "mode"
			if mode != "directory"
				-- lfs.attributes returns nil and no error if the folder wasn't
				-- found
				return nil, err if err
				-- create directory
				res, err = lfs.mkdir dir
				-- lfs.mkdir returns nil on success and error alike
				return nil, err if err

		-- make sure sha1 is lowercase for comparison.
		if sha1
			sha1 = sha1\lower!

		DM.addDownload @manager, url, outfile, sha1
		@downloadCount += 1
		@downloads[@downloadCount] = id:@downloadCount, :url, :outfile, :sha1
		return @downloads[@downloadCount]

	progress: =>
		return nil, msgs.notInitialized unless DM

		math.floor 100 * DM.progress @manager

	cancel: =>
		return nil, msgs.notInitialized unless DM

		DM.terminate @manager

	clear: =>
		return nil, msgs.notInitialized unless DM

		DM.clear @manager
		@downloads = {}
		@failedDownloads = {}
		@downloadCount = 0
		@failedCount = 0

	waitForFinish: ( callback ) =>
		return nil, msgs.notInitialized unless DM

		while 0 != DM.busy @manager
			if callback and not callback @progress!
				return
			sleep!

		@failedCount = 0
		for i = 1, @downloadCount
			err = DM.getError @manager, i
			if nil != err
				@failedCount +=1
				@failedDownloads[@failedCount] = @downloads[i]
				@downloads[i].error = ffi.string err

	-- These could be class methods rather than instance methods, but
	-- since DM has to be initialized for them to work, it's easier to
	-- just make them instance methods than trying to juggle the DM init.
	-- Also make them fat arrow functions for calling consistency.
	checkFileSHA1: ( filename, expected ) =>
		filenameType, expectedType = type(filename), type(expected)
		assert filenameType=="string" and expectedType=="string", msgs.checkMissingArgs\format filenameType, expectedType

		result = ffi.string DM.getFileSHA1 filename
		if nil == result
			return nil, "Could not open file #{filename}."
		if result == expected\lower!
			return true
		else
			return false, "Hash mismatch. Got #{result}, expected #{expected}."

	checkStringSHA1: ( string, expected ) =>
		stringType, expectedType = type(string), type(expected)
		assert stringType=="string" and expectedType=="string", msgs.checkMissingArgs\format stringType, expectedType

		result = ffi.string DM.getStringSHA1 string
		if result == expected\lower!
			return true
		else
			return false, "Hash mismatch. Got #{result}, expected #{expected}."
