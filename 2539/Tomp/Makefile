all: lib
	gcc -g -x c -c -m32 -o test.o test.c
	gcc -g -m32 -o test *.o

lib:
	yasm -gdwarf2 -felf32 -o hw_sprintf.o hw_sprintf.asm
