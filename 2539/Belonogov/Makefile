ASM_FLAGS = -f elf32 -g dwarf2 
CPP_FLAGS = -m32 -L. -g -fsanitize=address

all: test

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f test.o
	rm -f test

test: libhw.a test.o  
	g++ -o test $(CPP_FLAGS) test.o -lhw 

test.o: test.cpp  
	g++ -o test.o $(CPP_FLAGS) -c test.cpp 

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: hw_sprintf.asm
	yasm -o libhw.o $(ASM_FLAGS) hw_sprintf.asm
