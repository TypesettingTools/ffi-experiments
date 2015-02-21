ffi = require "ffi"
ffi.cdef [[
___INCLUDE___
int usleep(unsigned int useconds);
void Sleep(unsigned long dwMilliseconds);
]]

sleep = ffi.os == "Windows" and ( (ms=100) -> ffi.C.Sleep ms ) or ( (ms=100) -> ffi.C.usleep ms*1000 )

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
		if nil == DM
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
		unless url and outfile
			return nil, msgs.addMissingArgs\format tostring(url), tostring(outfile)

		dev, dir, file = outfile\match "^(#{ffi.os=='Windows' and '%a:[\\/]' or '[/~]'})(.*)[/\\](.*)$"

		-- check if outfile is a full path as we don't support relative ones or automatic file naming
		if not dev or #dir<1 and dev != "~"
			return nil, msgs.outNoFullPath\format outfile
		elseif #file<1
			return nil, msgs.outNoFile\format outfile

		dir = dev..dir
		-- check if directory exists
		mode, err = lfs.attributes dir, "mode"
		if mode != "directory"
			return nil, err if err -- lfs.attributes returns nil and no error if the folder wasn't found
			-- create directory
			res, err = lfs.mkdir dir
			return nil, err if err -- lfs.mkdir returns nil on sucess and error alike

		return nil, msgs.notInitialized unless DM

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

-- manager = DownloadManager!
-- manager\addDownload "https://a.real.website", "out1", "b52854d1f79de5ebeebf0160447a09c7a8c2cde4"
-- manager\addDownload "https://a.real.website", "out2", "this isn't a real sha1"
-- manager\addDownload "https://a.real.website", "out3"
-- -- Do whatever you want here while downloads happen in the background.

-- -- Call manager\waitForFinish(cb) to loop until remaining downloads
-- -- finish. The progress callback can call manager\cancel! or
-- -- manager\clear! to interrupt and break open connections.
-- manager\waitForFinish ( progress ) ->
-- 	print tostring progress

-- -- And get error strings.
-- for i = 1, manager.failedCount
-- 	idx = manager.failed[i]
-- 	print "Download #{idx} error: " .. manager.errorStrings[idx]
