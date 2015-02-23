all:
	yasm -o exit.o -f elf32 exit.a
	ld -o exit -melf_i386 exit.o
	./exit