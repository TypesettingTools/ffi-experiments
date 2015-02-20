CXX := clang++
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
	LIB_EXT :=.dylib
else
	LIB_EXT :=.so
endif

WARNINGS := -Wall -Wunreachable-code -Wfloat-equal -Wredundant-decls -Winit-self -Wpedantic
OPTIMIZATION := -O3
CXXFLAGS := $(WARNINGS) $(OPTIMIZATION) -std=c++11
LDFLAGS := -shared -fPIC
CPPSOURCES := $(wildcard *.cpp)
OBJECTS := $(CPPSOURCES:.cpp=.o)

OUTPUT := libPreciseTimer$(LIB_EXT)

.PHONY: all clean lua

all: $(OUTPUT) lua

$(OUTPUT): $(OBJECTS)
	@echo LINK $@
	@$(CXX) $^ $(LDFLAGS) -o $@

%.o: %.cpp
	@echo CXX $@
	@$(CXX) $(CXXFLAGS) -c $< -o $@

lua:
	$(shell ./preproclua.sh)

clean:
	rm -rf *.o *.processed.* $(OUTPUT)
