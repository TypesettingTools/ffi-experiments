#include "PreciseTimer.hpp"
#include "PreciseTimerC.h"
extern "C" {
	CPT* startTimer( void ) {
		return reinterpret_cast<CPT*>(new PreciseTimer);
	}

	double getDuration( CPT *pt ) {
		return reinterpret_cast<PreciseTimer*>(pt)->getElapsedTime( );
	}

	unsigned int version( void ) {
		return PreciseTimer::version;
	}

	void freeTimer( CPT *pt ) {
		delete reinterpret_cast<PreciseTimer*>(pt);
	}
}
