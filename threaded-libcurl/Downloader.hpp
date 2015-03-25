#pragma once
#include <string>
#include <thread>
#include <curl/curl.h>

#include "sha1.h"

std::string digestToHex( uint8_t digest[SHA1_DIGEST_SIZE] );

class Downloader {
	std::thread thread;
	char **etag = NULL;
	std::string url,
	            outfile,
	            sha1,
	            outBuffer;
	SHA1_CTX sha1ctx;
	bool hasSHA1  = false,
	     modified = true,
	     joined   = false;

	void finalize( void );

	public:
		bool terminated = false,
		     done       = false,
		     failed     = false;
	  std::string error;
		curl_off_t current = 0, total = 0;

		Downloader( const std::string &theUrl, const std::string &theOutfile, char **theEtag );
		Downloader( const std::string &theUrl, const std::string &theOutfile, const std::string &theSha1, char **theEtag );
		int progressCallback( curl_off_t dltotal, curl_off_t dlnow );
		size_t writeCallback( const char *buffer, size_t size );
		size_t headerCallback( const char *buffer, size_t size );
		void process( void );
		bool isFinished( void );
		void join( void );
};
