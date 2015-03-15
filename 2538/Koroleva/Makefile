all:
	yasm -o hw1.o -gdwarf2 -f elf32 hw1.asm
	ar rcs libhw.a hw1.o
	gcc -o hw1 -m32 -std=c99 -L. hw1.c -lhw
	gcc -o test -m32 -std=c99 -L. -Wno-format-extra-args -Wformat=0 test.c -lhw

clean:
	rm -f hw1.o libhw.a
