#include <string>
#include "DownloadManager.hpp"
#include "DownloadManagerC.h"

// Avoid symbol mangling.
extern "C" {
	CDlM *newDM( void ) {
		return reinterpret_cast<CDlM*>(new DownloadManager);
	}

	uint addDownload( CDlM *mgr, const char *url, const char *outfile, const char *sha1) {
		if (NULL == sha1) {
			return reinterpret_cast<DownloadManager*>(mgr)->addDownload( std::string(url), std::string(outfile) );
		} else {
			return reinterpret_cast<DownloadManager*>(mgr)->addDownload( std::string(url), std::string(outfile), std::string(sha1) );
		}
	}

	double progress( CDlM *mgr ) {
		return reinterpret_cast<DownloadManager*>(mgr)->getProgress( );
	}

	int busy( CDlM *mgr ) {
		return reinterpret_cast<DownloadManager*>(mgr)->busy( );
	}

	int checkDownload( CDlM *mgr, uint i ) {
		return reinterpret_cast<DownloadManager*>(mgr)->checkDownload( i );
	}

	const char* getError( CDlM *mgr, uint i ) {
		return reinterpret_cast<DownloadManager*>(mgr)->getError( i );
	}

	void terminate( CDlM *mgr ) {
		reinterpret_cast<DownloadManager*>(mgr)->terminate( );
	}

	void clear( CDlM *mgr ) {
		reinterpret_cast<DownloadManager*>(mgr)->clear( );
	}

	int checkFileSHA1( const char *filename, const char *expected ) {
		return DownloadManager::checkFileSHA1( std::string( filename ), std::string( expected ) );
	}

	int checkStringSHA1( const char *string, const char *expected ) {
		return DownloadManager::checkStringSHA1( std::string( string ), std::string( expected ) );
	}

	void freeDM( CDlM* mgr ) {
		delete reinterpret_cast<DownloadManager*>(mgr);
	}
}

/*
#include <cstdio>
#include <unistd.h> // usleep

int main( int argc, char **argv ) {
	CDlM *manager = newDM( );
	unsigned int count = 0;
	count = addDownload( manager, "https://a.real.website", "out1", "b52854d1f79de5ebeebf0160447a09c7a8c2cde4" );
	count = addDownload( manager, "https://a.real.website", "out2", "this isn't a real sha1" );
	count = addDownload( manager, "https://a.real.website", "out3", NULL );
	while (busy( manager ) > 0) {
		printf( "Progress: %g\n", progress( manager ) );
		usleep( 10000 );
	}

	for( int i = 1; i < count+1; ++i ) {
		const char *str = getError( manager, i );
		if (str) {
			printf( "Download %d error: %s\n", str );
		}
	}

	return 0;
}
*/
