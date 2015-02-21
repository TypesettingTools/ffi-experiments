ffi = require "ffi"
sleep = ( ms = 100 ) ->
	ffi.C.usleep ms*1000

if ffi.os == "Windows"
	ffi.cdef "void Sleep(unsigned long dwMilliseconds);"
	sleep = ( ms = 100 ) ->
		ffi.C.Sleep ms
else
	ffi.cdef "int usleep(unsigned int useconds);"

ffi.cdef [[
___INCLUDE___
]]

DM = nil

class DownloadManager
	freeManager = ( manager ) ->
		DM.freeDM manager

	new: ( libraryPath = "", library = "DownloadManager" ) =>
		if nil == DM
			success, DM = pcall ffi.load, libraryPath .. library
			unless success
				print "doof"
			assert success, DM
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
