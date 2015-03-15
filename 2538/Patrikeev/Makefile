ASM_FLAGS = -g dwarf2 -f elf32
CXX_FLAGS = -m32 -L. -g -I../../include

all: test

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f test.o
	rm -f test

test: libhw.a test.o
	g++ -o test $(CXX_FLAGS) test.o -lhw

test.o: test.cpp
	g++ -o test.o $(CXX_FLAGS) -c test.cpp

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: hw_sprintf.asm
	yasm -o libhw.o $(ASM_FLAGS) hw_sprintf.asm
