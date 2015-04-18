CFLAGS=-m32 -g

all: lal


lal: lal.o
	gcc $(CFLAGS) -o $@ $^

%.o: %.asm
	yasm -f elf32 -g dwarf2 -o $@ $^

