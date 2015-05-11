all: asm test

ar: asm
	ar rcs libhw.a hw_sprintf.o

test: ar test.cpp
	g++ -m32 -w -o test test.cpp libhw.a

asm: hw_sprintf.asm
	yasm -felf32 -gdwarf2 hw_sprintf.asm

clean:
	rm libhw.a
	rm *.o
	rm test
