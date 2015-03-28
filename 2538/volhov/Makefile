all: libhw.a

run: test
	./test

test: hw_sprintf.o test.cpp
	g++ -m32 -g -O3 -std=c++11 -o test test.cpp hw_sprintf.o

%.o: %.asm
	yasm -f elf32 -g dwarf2 -o $@ $^

libhw.a: hw_sprintf.o
	ar rcs libhw.a hw_sprintf.o

clean:
	rm -f *.o *.a
