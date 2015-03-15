all:
	yasm -o hw1.o -gdwarf2 -f elf32 hw1.asm
	ar rcs libhw.a hw1.o
clean:
	rm -f hw1.o libhw.a
