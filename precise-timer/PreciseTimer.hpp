#pragma once
#include <chrono>

class PreciseTimer {
	private:
		std::chrono::high_resolution_clock::time_point startTime;
		std::chrono::high_resolution_clock::time_point endTime;
		std::chrono::duration<double> timeSpan;
	public:
		PreciseTimer( void );
		double getElapsedTime( void );
};
