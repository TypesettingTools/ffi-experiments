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
		@failed = {}
		@downloads = 0
		@failedCount = 0
		@errorStrings = {}

	addDownload: ( url, outfile, sha1 ) =>
		if nil == DM
			return nil, "DM not initialized."

		DM.addDownload @manager, url, outfile, sha1
		@downloads += 1
		return @downloads

	progress: =>
		if nil == DM
			return nil, "DM not initialized."
		DM.progress @manager

	cancel: =>
		if nil == DM
			return nil, "DM not initialized."
		DM.terminate @manager

	clear: =>
		if nil == DM
			return nil, "DM not initialized."

		DM.clear @manager
		@failed = {}
		@downloads = 0
		@failedCount = 0
		@errorStrings = {}

	waitForFinish: ( callback ) =>
		if nil == DM
			return nil, "DM not initialized."
		while 0 != DM.busy @manager
			if nil != callback @progress!
				return
			sleep!

		-- This is horrible. Extracting errors from this is horrible. Why.
		@failedCount = 0
		for i = 1, @downloads
			err = DM.getError @manager, i
			if nil != err
				@failedCount += 1
				@failed[@failedCount] = i
				@errorStrings[i] = ffi.string err

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
