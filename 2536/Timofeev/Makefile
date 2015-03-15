ASM_FLAGS = -felf32
CXX_FLAGS = -m32 -std=c++11 -g -L.
all: clean libhw.a

libhw.a: hw.o
	ar rcs libhw.a hw.o

hw.o: hw1.asm
	yasm -o hw.o $(ASM_FLAGS) hw1.asm

clean :
	rm -f hw.o 