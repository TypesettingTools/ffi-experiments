#pragma once
#include <string>
#include <thread>
#include <curl/curl.h>

#include "sha1.h"

int sha1compare( uint8_t digest[SHA1_DIGEST_SIZE], const std::string sha1 );

class Downloader {
	std::thread thread;
	std::string url,
	            outfile,
	            sha1,
	            outBuffer;
	SHA1_CTX sha1ctx;
	bool hasSHA1 = false, joined = false;

	void finalize( void );

	public:
		bool terminated = false, done = false, failed = false;
	  std::string error;
		curl_off_t current, total;

		Downloader( std::string theUrl, std::string theOutfile );
		Downloader( std::string theUrl, std::string theOutfile, std::string theSha1 );
		int progressCallback( curl_off_t dltotal, curl_off_t dlnow );
		size_t writeCallback( const char *buffer, size_t size );
		void process( void );
		bool isFinished( void );
		void join( void );
};
