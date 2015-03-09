ASM_FLAGS = -f elf32 -g dwarf2
CXX_FLAGS = -m32 -g -L. -I../../include

all: test clean

clean:
	rm -f libhw_sprintf.a
	rm -f test.o

test: libhw_sprintf.a test.o
	g++ -o test $(CXX_FLAGS) test.o -lhw_sprintf

test.o: test.cpp
	g++ -o test.o $(CXX_FLAGS) -c test.cpp

libhw_sprintf.a: libhw_sprintf.o
	ar rcs libhw_sprintf.a libhw_sprintf.o

libhw_sprintf.o: hw_sprintf.asm
	yasm -o libhw_sprintf.o $(ASM_FLAGS) hw_sprintf.asm
