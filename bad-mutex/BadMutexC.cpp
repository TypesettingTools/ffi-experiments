#include "BadMutex.hpp"
#include "BadMutexC.h"

extern "C" {
	EXPORT void lock( void ) {
		BadMutex::getInstance().lock();
	}
	EXPORT void unlock( void ) {
		BadMutex::getInstance().unlock();
	}
}
