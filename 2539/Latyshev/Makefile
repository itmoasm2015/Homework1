ASM_FLAGS = -felf32 -gdwarf2

all: libhw.a 

clean:
	rm -f libhw.a
	rm -f hw.o

libhw.a: hw.o
	ar rcs libhw.a hw.o

hw.o: hw_sprintf.asm
	yasm -o hw.o $(ASM_FLAGS) hw_sprintf.asm
