#pragma once

#ifdef _WIN32
	#define snprintf( STR, SIZE, ... ) _snprintf_s( STR, SIZE, _TRUNCATE, __VA_ARGS__ )
#endif
