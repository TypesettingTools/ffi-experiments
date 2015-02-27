#pragma once
#include <mutex>

class BadMutex {
	public:
		static BadMutex& getInstance( void );
		void lock( void );
		void unlock( void );
		bool try_lock( void );
	private:
		std::mutex mutex;
		BadMutex( void );
};
