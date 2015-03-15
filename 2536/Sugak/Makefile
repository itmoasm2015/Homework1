ASM_FLAGS = -f elf32 -g dwarf2

all: libhw.a

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: hw_sprintf.asm
	yasm -o libhw.o $(ASM_FLAGS) hw_sprintf.asm
