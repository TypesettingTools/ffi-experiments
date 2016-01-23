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
	Errors will also be thrown if the wrong type is passed in to certain functions to avoid
	missing incorrect usage.
	If any other error is encountered the script will return nil along with an error message.

]]

havelfs, lfs = pcall require, "lfs"
ffi = require "ffi"
requireffi = require "requireffi.requireffi"
ffi.cdef [[
___INCLUDE___
int usleep(unsigned int);
void Sleep(unsigned long);
]]

DMVersion = 0x000400
DM, loadedLibraryPath = requireffi "DM.DownloadManager.DownloadManager"
libVer = DM.version!
if libVer < DMVersion or math.floor(libVer/65536%256) > math.floor(DMVersion/65536%256)
	error "Library version mismatch. Wanted #{DMVersion}, got #{libVer}."

sleep = ffi.os == "Windows" and (( ms = 100 ) -> ffi.C.Sleep ms) or (( ms = 100 ) -> ffi.C.usleep ms*1000)

sanitizeFile = ( filename, acceptDir ) ->
	-- expand leading ~.
	if homeDir = os.getenv "HOME"
		filename = filename\gsub "^~/", homeDir .. "/"

	dev, dir, file = filename\match "^(#{ffi.os == 'Windows' and '%a:[/\\]' or '/'})(.*[/\\])(.*)$"

	-- check that filename is a full path as we don't support relative
	-- ones or automatic file naming
	if not dev or #dir < 1
		return nil, msgs.outNoFullPath\format filename
	elseif not acceptDir and #file < 1
		return nil, msgs.outNoFile\format filename

	dir = dev .. dir
	if havelfs
		-- check that directory exists, but only if we have lfs.
		mode, err = lfs.attributes dir, "mode"
		if mode != "directory"
			-- lfs.attributes returns nil and no error if the folder wasn't
			-- found
			if err
				return nil, err
			-- create directory
			res, err = lfs.mkdir dir
			-- lfs.mkdir returns nil on success and error alike
			if err
				return nil, err

	else
		-- probably should care about the return code
		-- HAHA THIS IS HIDEOUSLY DANGEROUS, HOLY MOLEY
		os.execute "mkdir #{ffi.os == 'Windows' and '' or '-p '}\"#{dir}\""

	return dir .. file

class ETagCache
	-- DM class ensure cacheDir is an absolute file path and ends with a /.
	new: ( cacheDir ) =>
		@cacheDir = cacheDir

	cachedFile: ( cacheName ) =>
		return @cacheDir .. cacheName

	cachedFileExists: ( cacheName ) =>
		if cacheName == nil
			return false

		file = io.open @cachedFile( cacheName ), 'rb'
		if file == nil
			return false
		file\close!
		return true

	copyFile = ( source, target ) ->
		input, msg = io.open source, 'rb'
		if input == nil
			return input, msg
		-- assert input, msg
		output, msg = io.open target, 'wb'
		if output == nil
			input\close!
			return output, msg
		-- assert output, msg
		err, msg = output\write input\read '*a'
		if err == nil
			input\close!
			output\close!
			return err, msg

		input\close!
		output\close!
		return true

	useCache: ( download ) =>
		err, msg = copyFile @cachedFile( download.etag ), download.outfile
		if err == nil
			return err, msg
		return true

	cache: ( download ) =>
		err, msg = copyFile download.outfile, @cachedFile download.etag
		if err == nil
			return err, msg
		return true

class DownloadManager
	@version = 0x000400
	@version_string = "0.4.0"
	@__depCtrlInit = ( DependencyControl ) ->
		@version = DependencyControl {
			name: "#{@__name}",
			version: @version_string,
			description: "Download things with libcurl without blocking Lua.",
			author: "torque",
			url: "https://github.com/torque/ffi-experiments",
			moduleName: "DM.#{@__name}",
			feed: "https://raw.githubusercontent.com/torque/ffi-experiments/master/DependencyControl.json",
		}
	:loadedLibraryPath

	msgs = {
		notInitialized: "#{@__name} not initialized.",
		addMissingArgs: "Required arguments #1 (url) or #2 (outfile) had the wrong type. Expected string, got '%s' and '%s'.",
		checkMissingArgs: "Required arguments #1 (filename/string) and #2 (expected) or the wrong type. Expected string, got '%s' and '%s'.",
		outNoFullPath: "Argument #2 (outfile) must contain a full path (relative paths not supported), got %s.",
		outNoFile: "Argument #2 (outfile) must contain a full path with file name, got %s."
	}

	freeManager = ( manager ) ->
		DM.freeDM manager

	new: ( etagCacheDir ) =>
		@manager = ffi.gc DM.newDM!, freeManager
		@downloads       = { }
		@failedDownloads = { }
		if etagCacheDir
			result, message = sanitizeFile etagCacheDir\gsub( "[/\\]*$", "/", 1 ), true
			-- Really don't like having an assertion here, but failing
			-- silently is much worse, and failable constructors don't exist
			-- in moonscript without throwing errors.
			assert message == nil, message
			@cache = ETagCache result

	addDownload: ( url, outfile, sha1, etag ) =>
		return nil, msgs.notInitialized unless DM

		-- sha1 and etag types get (lazy) checked later.
		urlType, outfileType = type( url ), type outfile
		-- Don't use asserts.
		if urlType != "string" or outfileType != "string"
			return nil, msgs.addMissingArgs\format urlType, outfileType

		outfile, msg = sanitizeFile outfile
		if outfile == nil
			return outfile, msg

		-- make sure sha1 is lowercase for comparison.
		if "string" == type sha1
			sha1 = sha1\lower!
		else
			sha1 = nil

		if etag and "string" != type etag
			etag = nil
		if etag and @cache and not @cache\cachedFileExists etag
			-- if cached file does not exist, do not pass in an etag.
			etag = nil

		id = DM.addDownload @manager, url, outfile, sha1, etag
		if id == 0
			return nil, "Could not add download for some reason."

		download = { :id, :url, :outfile, :sha1, :etag }
		table.insert @downloads, download
		return download

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

	waitForFinish: ( callback ) =>
		return nil, msgs.notInitialized unless DM

		while 0 != DM.busy @manager
			if callback and not callback @progress!
				return
			sleep!

		pushFailed = ( download, message ) ->
			download.failed = true
			download.error = message
			table.insert @failedDownloads, download

		-- all downloads are finished at this point
		for download in *@downloads

			err = DM.getError @manager, download.id
			if err != nil
				pushFailed download, ffi.string err

			if @cache
				if DM.fileWasCached download.id
					err, msg = @cache\useCache download
					if err == nil
						pushFailed download, "Couldn't use cache. Message: " .. msg

				else
					newETag = DM.getETag download.id
					if newETag != nil
						download.etag = ffi.string newETag
						-- not technically an error if this fails
						@cache\cache download

			if "function" == type download.callback
				download\callback @

	-- These could be class methods rather than instance methods, but
	-- since DM has to be initialized for them to work, it's easier to
	-- just make them instance methods than trying to juggle the DM init.
	-- Also make them fat arrow functions for calling consistency.
	checkFileSHA1: ( filename, expected ) =>
		filenameType, expectedType = type( filename ), type expected
		if filenameType != "string" or expectedType != "string"
			return nil, msgs.checkMissingArgs\format filenameType, expectedType

		result = DM.getFileSHA1 filename
		if result == nil
			return nil, "Could not open file #{filename}."
		else
			result = ffi.string result

		if result == expected\lower!
			return true
		else
			return false, "Hash mismatch. Got #{result}, expected #{expected}."

	checkStringSHA1: ( string, expected ) =>
		stringType, expectedType = type( string ), type expected
		if stringType != "string" or expectedType != "string"
			msgs.checkMissingArgs\format stringType, expectedType

		result = DM.getStringSHA1 string
		if result == nil
			return nil, "Something has gone horribly wrong???"
		else
			result = ffi.string result

		if result == expected\lower!
			return true
		else
			return false, "Hash mismatch. Got #{result}, expected #{expected}."

	isInternetConnected: =>
		return DM.isInternetConnected!
