ASM_FLAGS = -f elf32
CXX_FLAGS = -m32 -L. -I../../include

all: libhw.a

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: hw_sprintf.asm
	yasm -g dwarf2 -o libhw.o $(ASM_FLAGS) hw_sprintf.asm

clean:
	rm -f libhw.a
	rm -f libhw.o
