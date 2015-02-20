CC  := clang
CXX := clang++
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
	LIB_EXT :=.dylib
else
	LIB_EXT :=.so
endif

WARNINGS := -Wall -Wunreachable-code -Wfloat-equal -Wredundant-decls -Winit-self -Wpedantic
OPTIMIZATION := -O3 -ggdb
CFLAGS := $(WARNINGS) $(OPTIMIZATION) -std=c99
CXXFLAGS := $(WARNINGS) $(OPTIMIZATION) -std=c++11
LDFLAGS := -lcurl -lc++ -ggdb -shared -fPIC
CPPSOURCES := $(wildcard *.cpp)
CSOURCES   := $(wildcard *.c)
OBJECTS := $(CPPSOURCES:.cpp=.o) $(CSOURCES:.c=.o)

OUTPUT := libDownloadManager$(LIB_EXT)

.PHONY: all clean lua

all: $(OUTPUT) lua

$(OUTPUT): $(OBJECTS)
	@echo LINK $@
	@$(CXX) $^ $(LDFLAGS) -o $@

%.o: %.c
	@echo CC $@
	@$(CC) $(CFLAGS) -c $< -o $@

%.o: %.cpp
	@echo CXX $@
	@$(CXX) $(CXXFLAGS) -c $< -o $@

lua:
	$(shell ./preproclua.sh)

clean:
	rm -rf *.o *.processed.* $(OUTPUT)
