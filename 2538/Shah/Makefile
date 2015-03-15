all: tester

tester: test
	./test

test: libhw.a test.o
	g++ -o test -m32 -g -L. -I../../include test.o -lhw

test.o: test.cpp
	g++ -o test.o -m32 -g -L. -I../../include -c test.cpp 

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: hw_sprintf.asm 
	yasm -o libhw.o -f elf32 -g dwarf2 hw_sprintf.asm

clean:
	rm -f libhw.a
	rm -f *.o
	rm -f ./test
