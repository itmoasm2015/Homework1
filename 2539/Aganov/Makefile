all: run

run: tester
	./tester

tester: libhw.a tester.c
	gcc -m32 -std=c99 tester.c libhw.a -o tester

libhw.a: hw_sprintf.o
	ar rc libhw.a hw_sprintf.o
	ranlib libhw.a

hw_sprintf.o: hw_sprintf.asm
	yasm -f elf32 -g dwarf2 -o hw_sprintf.o hw_sprintf.asm

