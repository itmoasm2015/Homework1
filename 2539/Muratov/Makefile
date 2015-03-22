CFLAGS = -m32 -g -std=c99

all: clean compile_and_run
	
clean:
	rm -f hw_sprintf.a
	rm -f hw_sprintf.o
	rm -f test.o
	rm -f test

compile_and_run: test.o hw_sprintf.a
	gcc $(CFLAGS) $^ -o test
	./test

test.o:
	gcc $(CFLAGS) -c -o $@ test.c

hw_sprintf.a: hw_sprintf.o
	ar rcs $@ $^

hw_sprintf.o: 
	yasm -f elf32 -g dwarf2 -o $@ hw_sprintf.asm
