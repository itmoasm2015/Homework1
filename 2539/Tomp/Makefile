all: lib
	gcc -x c -c -m32 -o test.o test.c
	gcc -m32 -o test *.o

lib:
	yasm -gdwarf2 -felf32 -o hw_sprintf.o hw_sprintf.asm
