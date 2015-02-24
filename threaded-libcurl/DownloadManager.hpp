#pragma once

#include <vector>
#include <string>
#include "Downloader.hpp"

class DownloadManager {
	std::vector<Downloader*> downloaders;
	unsigned int finishedCount = 0, addedCount = 0, failedCount = 0;

	public:
		const static unsigned int version = 0x000102;
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
		static std::string getFileSHA1( std::string filename );
		static std::string getStringSHA1( std::string string );
};
