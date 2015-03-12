ar: asm
	ar rcs libhw.a hw_sprintf.o

test: asm test.o
	g++ -m32 test.o hw_sprintf.o -o test

test.o: test.cpp
	g++ --std=c++11 test.cpp -m32 -g -c -o test.o

asm: hw_sprintf.asm
	yasm -felf32 -gdwarf2 -Worphan-labels -Werror hw_sprintf.asm
