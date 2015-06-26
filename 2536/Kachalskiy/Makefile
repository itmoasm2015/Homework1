ASM_FLAGS= -f elf32 -g dwarf2
CFLAGS= -m32 -L. -I../../include
all: test.o libhw.a
	g++ -o test $(CFLAGS) test.o -lhw

test.o: test.cpp
	g++ -o test.o $(CFLAGS) -c test.cpp

libhw.a: hw_sprintf.o	
	ar rcs libhw.a hw_sprintf.o

hw_sprintf.o: hw_sprintf.asm
	yasm -o hw_sprintf.o $(ASM_FLAGS) hw_sprintf.asm

clean: 
	rm -f libhw.a
	rm -f hw_sprintf.o
	rm -f test.o
	rm -f test	
