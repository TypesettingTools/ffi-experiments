#include "BadMutex.hpp"

BadMutex::BadMutex( void ) : mutex() {}

BadMutex& BadMutex::getInstance( void ) {
	static BadMutex instance;
	return instance;
}

void BadMutex::lock( void ) {
	mutex.lock( );
}

void BadMutex::unlock( void ) {
	mutex.unlock( );
}
