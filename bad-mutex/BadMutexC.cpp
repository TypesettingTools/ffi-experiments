#include "BadMutex.hpp"
#include "BadMutexC.h"
#include <cstdio>

extern "C" {
	EXPORT void lock( void ) {
		BadMutex::getInstance().lock();
		puts("locked");
	}
	EXPORT void unlock( void ) {
		BadMutex::getInstance().unlock();
		puts("unlocked");
	}
}
