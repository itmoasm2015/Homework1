all:
	yasm -gdwarf2 -felf32 -o hw_sprintf.o hw_sprintf.asm
	ar rcs libhw.a hw_sprintf.o

test: all
	gcc -o test -x c -m32 -g -L. test.c -lhw
