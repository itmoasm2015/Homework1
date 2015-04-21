# Created by PaulChristmas
# 10.04.15

# Compilers
TESTC=gcc
ASMC=yasm

# Flags
FLAGS=-f elf32 -g dwarf2

# Program name
NAME=hw_sprintf

all: libhw.a test

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: $(NAME).asm
	$(ASMC) -o libhw.o $(FLAGS) $(NAME).asm

test:
	$(TESTC) -o tester -x c -m32 -g -L. test.c -lhw
	./tester
	
clean:
	rm -f *.o
	rm -f *.a
	rm -f tester

