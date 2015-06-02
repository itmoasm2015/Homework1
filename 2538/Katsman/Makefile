FLAGS= -f elf32 -g dwarf2
CFLAGS= -m32 -L. -I../../include

all: test.o libhw.a
	g++ -o test $(CFLAGS) test.o -lhw
	rm -f libhw.a
	rm -f hw_sprintf.o
	rm -f test.o

test.o: test.cpp
	g++ -o $@ $(CFLAGS) -c $<

libhw.a: hw_sprintf.o
	ar rcs $@ $<

hw_sprintf.o: hw_sprintf.asm
	yasm -o $@ $(FLAGS) $<

clean:
	rm -f libhw.a
	rm -f hw_sprintf.o
	rm -f test.o
	rm -f test
