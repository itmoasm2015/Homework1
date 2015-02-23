ASM_FLAGS = -f elf32 -g dwarf2
CFLAGS = -m32 -g -L. -I../../include

all: tests

tests: libhw.a tests.o
	gcc -o tests $(CFLAGS) tests.o -lhw

tests.o: tests.c
	gcc -o tests.o $(CFLAGS) -c tests.c

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: libhw.asm
	yasm -o libhw.o $(ASM_FLAGS) libhw.asm

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f tests.o
