#include "BadMutex.hpp"

BadMutex::BadMutex( void ) : mutex() {}

BadMutex& BadMutex::getInstance( void ) {
	static BadMutex instance;
	return instance;
}

void BadMutex::lock( void ) {
	mutex.lock( );
}

bool BadMutex::try_lock( void ) {
	return mutex.try_lock( );
}

void BadMutex::unlock( void ) {
	mutex.unlock( );
}
