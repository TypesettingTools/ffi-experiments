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
char *strdup(const char *);
char *_strdup(const char *);
]]

DMVersion = 0x000200
DM, loadedLibraryPath = requireffi "DM.DownloadManager"
libVer = DM.version!
if libVer < DMVersion or math.floor(libVer/65536%256) > math.floor(DMVersion/65536%256)
	error "Library version mismatch. Wanted #{DMVersion}, got #{libVer}."

sleep = ffi.os == "Windows" and (( ms = 100 ) -> ffi.C.Sleep ms) or (( ms = 100 ) -> ffi.C.usleep ms*1000)
strdup = ffi.os == "Windows" and ffi.C._strdup or ffi.C.strdup

class DownloadManager
	@version = 0x000201
	@version_string = "0.2.1"
	@attachDepctrl = (DependencyControl) ->
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
		@downloadCount   = 0
		@failedDownloads = { }
		@failedCount     = 0
		if etagCacheDir
			result, message  = sanitizeFile etagCacheDir\gsub( "[/\\]*$", "/", 1 ), true
			assert message == nil, message
			@cacheDir        = result

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
				return nil, err if err
				-- create directory
				res, err = lfs.mkdir dir
				-- lfs.mkdir returns nil on success and error alike
				return nil, err if err

		else
			-- probably should care about the return code
			os.execute "mkdir #{ffi.os == 'Windows' and '' or '-p '}\"#{dir}\""

		return dir .. file

	getCachedFile = ( etag ) =>
		return @cacheDir .. etag

	copyFile = ( source, target ) ->
		-- actually handling errors is for big chumps.
		input,  msg = io.open source, 'rb'
		assert input, msg
		output, msg = io.open target, 'wb'
		assert output, msg
		err,    msg = output\write input\read '*a'
		assert err, msg
		input\close!
		output\close!

	etagCacheCheck = ( manager ) =>
		source = getCachedFile manager, @newEtag
		-- if the newEtag matches the provided etag then nothing was
		-- actually downloaded, so we need to copy the cached file to the
		-- expected output.
		if @newEtag == @etag
			-- should probably check if source exists.
			copyFile source, @outfile

		-- otherwise, the file was downloaded and we need to copy it into
		-- our etag cache directory.
		else
			copyFile @outfile, source

	addDownload: ( url, outfile, sha1, etag ) =>
		return nil, msgs.notInitialized unless DM

		-- sha1 and etag types get (lazy) checked later.
		urlType, outfileType = type( url ), type outfile
		assert urlType == "string" and outfileType == "string", msgs.addMissingArgs\format urlType, outfileType

		outfile, msg = sanitizeFile outfile
		if outfile == nil
			return outfile, msg

		-- make sure sha1 is lowercase for comparison.
		if "string" == type sha1
			sha1 = sha1\lower!
		else
			sha1 = nil

		cEtag = ffi.new "char*[1]"
		if "string" == type etag
			cEtag[0] = strdup etag
		else
			cEtag[0] = strdup ""

		DM.addDownload @manager, url, outfile, sha1, cEtag
		@downloadCount += 1
		@downloads[@downloadCount] = { id: @downloadCount, :url, :outfile, :sha1, :etag, :cEtag }
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
			download = @downloads[i]
			if download.cEtag != nil
				if download.cEtag[0] != nil
					download.newEtag = ffi.string download.cEtag[0]
				-- I think this actually leaks the string at cEtag[0].
				download.cEtag = nil

			err = DM.getError @manager, i
			if err != nil
				@failedCount += 1
				@failedDownloads[@failedCount] = download
				download.error = ffi.string err
				download.failed = true

			if @cacheDir and download.newEtag and not download.failed
				err, msg = pcall etagCacheCheck, download, @
				if not err
					download.error = "Etag cache check failed with message: " .. msg
					download.failed = true

			if "function" == type download.callback
				download\callback @

	-- These could be class methods rather than instance methods, but
	-- since DM has to be initialized for them to work, it's easier to
	-- just make them instance methods than trying to juggle the DM init.
	-- Also make them fat arrow functions for calling consistency.
	checkFileSHA1: ( filename, expected ) =>
		filenameType, expectedType = type( filename ), type expected
		assert filenameType == "string" and expectedType == "string", msgs.checkMissingArgs\format filenameType, expectedType

		result = DM.getFileSHA1 filename
		if nil == result
			return nil, "Could not open file #{filename}."
		else
			result = ffi.string result

		if result == expected\lower!
			return true
		else
			return false, "Hash mismatch. Got #{result}, expected #{expected}."

	checkStringSHA1: ( string, expected ) =>
		stringType, expectedType = type( string ), type expected
		assert stringType == "string" and expectedType == "string", msgs.checkMissingArgs\format stringType, expectedType

		result = ffi.string DM.getStringSHA1 string
		if result == expected\lower!
			return true
		else
			return false, "Hash mismatch. Got #{result}, expected #{expected}."

	isInternetConnected: =>
		return DM.isInternetConnected!
