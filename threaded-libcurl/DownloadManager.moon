[[   ---------- Usage ----------

1. Create a DownloadManager:

	manager = DownloadManager!

	You can supply a single library search path or a table of search paths for the DownloadManager library.
	On Aegisub, this will default to the system and user DownloadManager module directories.
	Otherwise the default library search path will be used.

2. Add some downloads:

	manager\addDownload "https://a.real.website", "out3"

	If you have a SHA-1 hash to check the downloaded file against, use:
		manager\addDownload "https://a.real.website", "out2", "b52854d1f79de5ebeebf0160447a09c7a8c2cde4"

	You may want to keep the ID of your download to check its result later:
		id = manager\addDownload "https://a.real.website", "out2",

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
		if manager\error[id]
			error manager\error[id]

	Get a list of failed downloads:
		for id in *manager.failedDownloads
			print "Download #{id} error: #{manager.error[id]}"

5. Clear all downloads:

	manager\clear!

	Removes all downloads as well as results/error messages, so previous IDs become invalid.


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

class DownloadManager
	DM = nil
	pathExt = "/automation/include/#{@__name}/#{@__name}.#{(OSX: 'dylib', Windows: 'dll')[ffi.os] or 'so'}"
	defaultLibraryPaths = aegisub and {aegisub.decode_path("?user"..pathExt), aegisub.decode_path("?data"..pathExt)} or {@__name}
	msgs = {
		notInitialized: "#{@__name} not initialized.",
		addMissingArgs: "Arguments #1 (url) and #2 (outfile) must not be nil, got url=%s, outfile=%s.",
		outNoFullPath: "Argument #2 (outfile) must contain a full path (relative paths not supported), got %s.",
		outNoFile: "Argument #2 (outfile) must contain a full path with file name, got %s."
	}

	freeManager = ( manager ) ->
		DM.freeDM manager

	new: ( libraryPaths = defaultLibraryPaths ) =>
		unless DM
			libraryPaths = {libraryPaths} unless "table" == type libraryPaths
			success = false
			for path in *libraryPaths
				success, DM = pcall ffi.load, path
				break if success

			error DM unless success

		@manager = ffi.gc DM.newDM!, freeManager
		@failedDownloads = {}
		@downloadCount = 0
		@failedCount = 0
		@error = {}

	addDownload: ( url, outfile, sha1 ) =>
		return nil, msgs.notInitialized unless DM
		unless url and outfile
			return nil, msgs.addMissingArgs\format tostring(url), tostring(outfile)

		dev, dir, file = outfile\match "^(#{ffi.os=='Windows' and '%a:[\\/]' or '[/~]'})(.*)[/\\](.*)$"

		-- check if outfile is a full path as we don't support relative ones or automatic file naming
		if not dev or #dir<1 and dev != "~"
			return nil, msgs.outNoFullPath\format outfile
		elseif #file<1
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

		DM.addDownload @manager, url, outfile, sha1
		@downloadCount += 1
		return @downloadCount

	progress: =>
		return nil, msgs.notInitialized unless DM

		math.floor 100 * DM.progress @manager

	cancel: =>
		return nil, msgs.notInitialized unless DM

		DM.terminate @manager

	clear: =>
		return nil, msgs.notInitialized unless DM

		DM.clear @manager
		@failedDownloads = {}
		@downloadCount = 0
		@failedCount = 0
		@error = {}

	waitForFinish: ( callback ) =>
		return nil, msgs.notInitialized unless DM

		while 0 != DM.busy @manager
			unless callback @progress!
				return
			sleep!

		@failedCount = 0
		for i = 1, @downloadCount
			err = DM.getError @manager, i
			if nil != err
				@failedCount +=1
				@failedDownloads[@failedCount] = i
				@error[i] = ffi.string err
