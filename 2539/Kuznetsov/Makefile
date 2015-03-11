ASM_FLAGS = -fwin32 
CXX_FLAGS = -m32 -std=c99 -L. -Wno-format-extra-args -Wformat=0

all: test

clean:
	rm -f libhw.a
	rm -f hw.o
	rm -f test

test: libhw.a
	gcc -o test.exe $(CXX_FLAGS) test.c -lhw

libhw.a: hw.o
	ar rcs libhw.a hw.o

hw.o: hw_sprintf.asm
	yasm -o hw.o $(ASM_FLAGS) hw_sprintf.asm
