CFLAGS=-m32 -g
CXXFLAGS=-m32 -g -O2 -std=c++11

all: test libhw.a

test: test.o hw.o
	g++ $(CXXFLAGS) -o $@ $^

libhw.a: hw.o
	ar rcs libhw.a hw.o

%.o: %.asm
	yasm -f elf32 -g dwarf2 -o $@ $^

