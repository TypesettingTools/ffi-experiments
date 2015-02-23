#pragma once

#include <vector>
#include <string>
#include "Downloader.hpp"

class DownloadManager {
	std::vector<Downloader*> downloaders;
	unsigned int finishedCount = 0, addedCount = 0, failedCount = 0;

	public:
		const static unsigned int version = 0x000100;
		DownloadManager( void );
		~DownloadManager( void );
		double getProgress( void );
		unsigned int addDownload( std::string url, std::string outfile );
		unsigned int addDownload( std::string url, std::string outfile, std::string sha1 );
		int checkDownload( unsigned int i );
		const char* getError( unsigned int i );
		void terminate( void );
		void clear( void );
		int busy( void );
		static int checkFileSHA1( std::string filename, std::string expected );
		static int checkStringSHA1( std::string string, std::string expecteds );
};
