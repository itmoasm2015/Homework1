CFLAGS=-m32 -g
CXXFLAGS=-m32 -g -O2 -std=c++11

libhw.a: asm
	ar rcs libhw.a hw_sprintf.o

test: test.o
	g++ -m32 -g -O2  -o test test.o hw_sprintf.o

test.o: test.cpp asm
	g++ -m32 -g -O2 -std=c++11 -o test.o -c test.cpp

asm: hw_sprintf.asm
	yasm -f elf32 -g dwarf2 -o $@ $^
