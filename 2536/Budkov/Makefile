ASM_FLAGS = -f elf32 -g dwarf2
CXX_FLAGS = -m32 -L. -g -I.

all: test clean

clean:
	rm -f libhw.o
	rm -f test.o

test: libhw.a test.o
	g++ -o test $(CXX_FLAGS) test.o -lhw

test.o: test.cpp
	g++ -o test.o $(CXX_FLAGS) -c test.cpp

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: hw_sprintf.asm
	yasm -o libhw.o $(ASM_FLAGS) hw_sprintf.asm
