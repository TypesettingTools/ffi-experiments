#include <iostream>
#include <fstream>
#include <cstdint>
#include <cstdio>
#include <cstdlib>

#include "Downloader.hpp"

static size_t curlWriteCallback( char *buffer, size_t size, size_t nitems, void *userdata ) {
	return static_cast<Downloader*>(userdata)->writeCallback( buffer, size*nitems );
}

static int curlProgressCallback( void *userdata, curl_off_t dltotal, curl_off_t dlnow, curl_off_t ultotal, curl_off_t ulnow ) {
	return static_cast<Downloader*>(userdata)->progressCallback( dltotal, dlnow );
}

static size_t curlHeaderCallback( char *buffer, size_t size, size_t nitems, void *userdata ) {
	return static_cast<Downloader*>(userdata)->headerCallback( buffer, size*nitems );
}

std::string digestToHex( uint8_t digest[SHA1_DIGEST_SIZE] ) {
	char hash[41];
	for( unsigned int offset = 0; offset < SHA1_DIGEST_SIZE; offset++ ) {
#ifdef _WIN32
		_snprintf_s( hash + 2*offset, 3, _TRUNCATE, "%02x", digest[offset]);
#else
		snprintf( hash + 2*offset, 3, "%02x", digest[offset] );
#endif // _WIN32
	}
	return std::string(hash);
}

Downloader::Downloader( const std::string &theUrl, const std::string &theOutfile, char **theEtag ) {
	url     = theUrl;
	outfile = theOutfile;
	if (*theEtag != NULL)
		etag  = theEtag;

	thread = std::thread( &Downloader::process, this );
}

Downloader::Downloader( const std::string &theUrl, const std::string &theOutfile, const std::string &theSha1, char **theEtag ) {
	url     = theUrl;
	outfile = theOutfile;
	if (*theEtag != NULL)
		etag  = theEtag;

	hasSHA1 = true;
	sha1    = theSha1;
	SHA1_Init( &sha1ctx );

	thread = std::thread( &Downloader::process, this );
}

int Downloader::progressCallback( curl_off_t dltotal, curl_off_t dlnow ) {
	current = dlnow;
	total = dltotal;
	return terminated? !CURLE_OK: CURLE_OK;
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

size_t Downloader::headerCallback( const char *buffer, size_t size ) {
	if (strncmp( buffer, "HTTP/1.1 304 Not Modified", 25 ) == 0) {
		modified = false;
	}
	if (strncmp( buffer, "ETag: ", 6) == 0) {
		// don't leak old etag string.
		free( *etag );
		// cut off an extra two chars because buffer is CRLF terminated.
		*etag = strndup( buffer + 7, size - 10 );
	}
	return size;
}

void Downloader::finalize( void ) {
	if (terminated)
		return;

	if (hasSHA1) {
		uint8_t digest[SHA1_DIGEST_SIZE];
		SHA1_Final( &sha1ctx, digest );
		auto result = digestToHex( digest );
		if ( result != sha1 ) {
			error = "Hash mismatch. Got " + result + ", expected " + sha1;
			failed = true;
			return;
		}
	}
	if (modified) {
		std::fstream outStream( outfile, std::ios::out | std::ios::binary );
		if (outStream.fail( )) {
			error = "Couldn't open output file: " + outfile;
			failed = true;
			return;
		}

		outStream << outBuffer;
		outStream.close( );
	}
}

void Downloader::process( void ) {
	char curlError[CURL_ERROR_SIZE];
	CURL *curl = curl_easy_init( );
	struct curl_slist *slist = NULL;
	if ( NULL == curl ) {
		error = "Could not initialize curl.";
		failed = true;
		goto exit;
	}

	if ( etag != NULL ) {
		char header[256];
		snprintf( header, 256, "If-None-Match: \"%s\"", *etag );
		slist = curl_slist_append( slist, header );
		if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_HTTPHEADER, slist )) {
			error = "Could not set http headers.";
			goto fail;
		}
		if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_HEADERDATA, this )) {
			error = "Could not set progress callback.";
			goto fail;
		}
		if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_HEADERFUNCTION, curlHeaderCallback ) ) {
			error = "Could not set header callback.";
			goto fail;
		}
	}

	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_WRITEDATA, this )) {
		error = "Could not set write callback.";
		goto fail;
	}
	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_WRITEFUNCTION, curlWriteCallback )) {
		error = "Could not set write callback.";
		goto fail;
	}
	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_NOPROGRESS, 0 )) {
		error = "Could not enable progress callback????";
		goto fail;
	}
	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_XFERINFODATA, this )) {
		error = "Could not set progress callback.";
		goto fail;
	}
	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_XFERINFOFUNCTION, curlProgressCallback )) {
		error = "Could not set progress callback.";
		goto fail;
	}
	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_FAILONERROR, 1 ) ) {
		error = "Could not fail on error.";
		goto fail;
	}
	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_URL, url.c_str( ) )) {
		error = "Could not set fetch url.";
		goto fail;
	}
	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_FOLLOWLOCATION, 1 ) ) {
		error = "Could not set redirect following.";
		goto fail;
	}
	if (CURLE_OK != curl_easy_setopt( curl, CURLOPT_ERRORBUFFER, curlError )) {
		error = "Could not set error buffer.";
		goto fail;
	}

	switch (curl_easy_perform( curl )) {
	case CURLE_OK:
		break;

	case CURLE_ABORTED_BY_CALLBACK:
		error = "User aborted.";
		goto fail;

	case CURLE_WRITE_ERROR:
		error = "A write error occurred.";
		goto fail;

	default:
		error = std::string( curlError );
		goto fail;
	}

	finalize( );
	goto cleanup;

fail:
	failed = true;
cleanup:
	curl_slist_free_all( slist );
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
