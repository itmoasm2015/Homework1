CFLAGS=-m32 -g
CXXFLAGS=-m32 -g -O3 -std=c++11

all: test lib

test: test.o hw_sprintf.o
	g++ $(CXXFLAGS) -o $@ $^

lib: hw_sprintf.o
	ar rcs libhw.a $^

%.o: %.asm
	yasm -f elf32 -g dwarf2 -o $@ $^

clean:
	rm -f *.o test
