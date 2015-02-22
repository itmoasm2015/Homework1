ASM_FLAGS = -f elf32
CXX_FLAGS = -m32 -L. -I../../include

all: tester

clean:
	rm -f libhw.a
	rm -f libhw.o
	rm -f tester.o

tester: libhw.a tester.o
	g++ -o tester $(CXX_FLAGS) tester.o -lhw

tester.o: tester.cpp
	g++ -o tester.o $(CXX_FLAGS) -c tester.cpp

libhw.a: libhw.o
	ar rcs libhw.a libhw.o

libhw.o: hw_sprintf.asm
	yasm -o libhw.o $(ASM_FLAGS) hw_sprintf.asm
