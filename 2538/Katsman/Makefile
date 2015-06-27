FLAGS= -f elf32 -g dwarf2
CFLAGS= -m32 -L. -I../../include
PROJECT=hw_sprintf

all: test.o libhw.a
	g++ -o test $(CFLAGS) test.o -lhw
	rm -f $(PROJECT).o
	rm -f test.o

test.o: test.cpp
	g++ -o $@ $(CFLAGS) -c $<

libhw.a: $(PROJECT).o
	ar rcs $@ $<

$(PROJECT).o: $(PROJECT).asm
	yasm -o $@ $(FLAGS) $<

clean:
	rm -f libhw.a
	rm -f $(PROJECT).o
	rm -f test.o
	rm -f test
