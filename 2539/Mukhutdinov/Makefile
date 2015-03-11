CFLAGS=-m32 -g
CXXFLAGS=-m32 -g -O3 -std=c++11

all: test


test: test.o hw1.o
	g++ $(CXXFLAGS) -o $@ $^

%.o: %.asm
	yasm -f elf32 -g dwarf2 -o $@ $^
