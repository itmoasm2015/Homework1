ASM_FLAGS = -f elf32
CXX_FLAGS = -m32 -L. -I../../include

all: test

test: libhw.a test.o
	 g++ -g -o test $(CXX_FLAGS) test.o -lhw

test.o: test.cpp
	g++ -g -o test.o $(CXX_FLAGS) -c test.cpp

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: hw_sprintf.asm
	yasm -g dwarf2 -o libhw.o $(ASM_FLAGS) hw_sprintf.asm

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f test
	rm -f test.o
