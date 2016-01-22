#pragma once

#if !defined(NDEBUG)
	#define DEBUG_LOG(log) std::cout << log << std::endl
#else
	#define DEBUG_LOG(x)
#endif
