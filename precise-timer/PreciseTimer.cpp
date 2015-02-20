#include <chrono>
#include "PreciseTimer.hpp"

PreciseTimer::PreciseTimer( void ) {
	startTime = std::chrono::high_resolution_clock::now( );
}

double PreciseTimer::getElapsedTime( void ) {
	endTime = std::chrono::high_resolution_clock::now( );
	timeSpan = std::chrono::duration_cast<std::chrono::duration<double>>(endTime - startTime);
	return timeSpan.count( );
}
