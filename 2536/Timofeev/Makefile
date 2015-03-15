ASM_FLAGS = -felf32
CXX_FLAGS = -m32 -std=c++11 -g -L.
all: clean test

test: libhw.a
	g++ -o test $(CXX_FLAGS) test.cpp -lhw

libhw.a: hw.o
	ar rcs libhw.a hw.o

hw.o: hw1.asm
	yasm -o hw.o $(ASM_FLAGS) hw1.asm

clean :
	rm -f hw.o test.o libhw.a