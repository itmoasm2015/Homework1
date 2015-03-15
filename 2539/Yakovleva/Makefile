ASM_FLAGS = -f elf32 -g dwarf2

all: 
	yasm -o hw_sprintf.o $(ASM_FLAGS) hw_sprintf.asm
	ar rcs libhw.a hw_sprintf.o
	g++ -o test.o -m32 -L. -c test.cpp
	g++ -o test -m32 -L. test.o -lhw

clean:
	rm -f libhw.a
	rm -f hw_sprintf.o
	rm -f test.o
	rm -f test

