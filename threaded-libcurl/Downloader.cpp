#include <iostream>
#include <fstream>
#include <cstdint>
#include <cstdio>

#include "Downloader.hpp"

static size_t curlWriteCallback( char *buffer, size_t size, size_t nitems, void *userdata ) {
	return static_cast<Downloader*>(userdata)->writeCallback( buffer, size*nitems );
}

static int curlProgressCallback( void *userdata, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow ) {
	return static_cast<Downloader*>(userdata)->progressCallback( dltotal, dlnow );
}

int sha1compare( uint8_t digest[SHA1_DIGEST_SIZE], const std::string sha1 ) {
	char hash[41];
	for( unsigned int offset = 0; offset < SHA1_DIGEST_SIZE; offset++ ) {
#ifdef _WIN32
		_snprintf_s( hash + 2*offset, 3, _TRUNCATE, "%02x", digest[offset]);
#else
		snprintf( hash + 2*offset, 3, "%02x", digest[offset] );
#endif // _WIN32
	}
	return (std::string(hash) != sha1);
}

Downloader::Downloader( std::string theUrl, std::string theOutfile ) {
	url     = theUrl;
	outfile = theOutfile;
	thread = std::thread( &Downloader::process, this );
}

Downloader::Downloader( std::string theUrl, std::string theOutfile, std::string theSha1 ) {
	hasSHA1 = true;
	url     = theUrl;
	sha1    = theSha1;
	outfile = theOutfile;
	SHA1_Init( &sha1ctx );

	thread = std::thread( &Downloader::process, this );
}

int Downloader::progressCallback( curl_off_t dltotal, curl_off_t dlnow ) {
	current = dlnow;
	total = dltotal;
	return terminated? 1: 0;
}

size_t Downloader::writeCallback( const char *buffer, size_t size ) {
	outBuffer.append( buffer, size );
	if (hasSHA1) {
		// This seems to calculate the sha1 correctly but buffer gets
		// corrupted somehow. Is it the cast? Is it the function?
		// SHA1_Update just memcpy's from the buffer, so it shouldn't be to
		// blame. Easiest fix is to append before hashing.
		SHA1_Update( &sha1ctx, reinterpret_cast<const uint8_t*>(buffer), size );
	}
	return size;
}

void Downloader::finalize( void ) {
	if (terminated)
		return;

	if (hasSHA1) {
		uint8_t digest[SHA1_DIGEST_SIZE];
		SHA1_Final( &sha1ctx, digest );
		if (sha1compare( digest, sha1 )) {
			error = "sha1 mismatch.";
			failed = true;
			return;
		}
	}

	std::fstream outStream( outfile, std::fstream::out );
	if (outStream.fail( )) {
		error = "Couldn't open output file: " + outfile;
		failed = true;
		return;
	}

	outStream << outBuffer;
	outStream.close( );
}

void Downloader::process( void ) {
	CURL *curl = curl_easy_init( );
	if ( NULL == curl ) {
		error = "Could not initialize curl.";
		failed = true;
		goto exit;
	}

	if (curl_easy_setopt( curl, CURLOPT_WRITEDATA, this )) {
		error = "Could not set write callback.";
		goto fail;
	}
	if (curl_easy_setopt( curl, CURLOPT_WRITEFUNCTION, curlWriteCallback )) {
		error = "Could not set write callback.";
		goto fail;
	}
	if (curl_easy_setopt( curl, CURLOPT_NOPROGRESS, 0 )) {
		error = "Could not enable progress callback????";
		goto fail;
	}
	if (curl_easy_setopt( curl, CURLOPT_XFERINFODATA, this )) {
		error = "Could not set progress callback.";
		goto fail;
	}
	if (curl_easy_setopt( curl, CURLOPT_XFERINFOFUNCTION, curlProgressCallback )) {
		error = "Could not set progress callback.";
		goto fail;
	}
	if (curl_easy_setopt( curl, CURLOPT_URL, url.c_str( ) )) {
		error = "Could not set fetch url.";
		goto fail;
	}

	switch (curl_easy_perform( curl )) {
	case 0:
		break;

	case CURLE_ABORTED_BY_CALLBACK:
		error = "User aborted.";
		goto fail;

	case CURLE_WRITE_ERROR:
		error = "A write error occurred.";
		goto fail;

	default:
		error = "The download could not be completed.";
		goto fail;
	}

	finalize( );
	goto cleanup;

fail:
	failed = true;
cleanup:
	curl_easy_cleanup( curl );
exit:
	done = true;
	return;
}

bool Downloader::isFinished( void ) {
	return done && !joined;
}

void Downloader::join( void ) {
	if (joined)
		return;

	thread.join( );
	joined = true;
}
