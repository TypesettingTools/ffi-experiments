#pragma once

#include <vector>
#include <string>
#include "Downloader.hpp"

class DownloadManager {
	std::vector<Downloader*> downloaders;
	unsigned int finishedCount = 0, addedCount = 0, failedCount = 0;

	public:
		const static unsigned int version = 0x000200;
		DownloadManager( void );
		~DownloadManager( void );
		double getProgress( void );
		unsigned int addDownload( const std::string &url, const std::string &outfile, char **etag );
		unsigned int addDownload( const std::string &url, const std::string &outfile, const std::string &sha1, char **etag );
		int checkDownload( unsigned int i );
		const char* getError( unsigned int i );
		void terminate( void );
		void clear( void );
		int busy( void );
		static std::string getFileSHA1( const std::string &filename );
		static std::string getStringSHA1( const std::string &string );
};
