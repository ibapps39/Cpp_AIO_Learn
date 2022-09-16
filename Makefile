//find c++ makefile template .
// Source: https://stackoverflow.com/a/32160588 .
appname := myapp

CXX := g++

CXXFLAGS := -Wall -g 

srcfiles := $(shell find . -maxdepth 1 -name "*.cpp")
objects  := $(patsubst %.cpp, %.o, $(srcfiles))

all: $(appname)

$(appname): $(objects)
    $(CXX) $(CXXFLAGS) $(LDFLAGS) -o $(appname) $(objects) $(LDLIBS)

depend: .depend

.depend: $(srcfiles)
    rm -f ./.depend
    $(CXX) $(CXXFLAGS) -MM $^>>./.depend;

clean:
    rm -f $(objects)

dist-clean: clean
    rm -f *~ .depend

include .depend



