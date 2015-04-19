CFLAGS=-m32 -g
CXXFLAGS=-m32 -g -O3 -std=c++11
LDFLAGS=
UNAME=$(shell uname)

ifeq ($(UNAME), Darwin)
	YFLAGS=-f macho32
	CXXFLAGS +=  -stdlib=libstdc++
	LDFLAGS += -Wl,-no-pie
else
	YFLAGS=-f elf32 -g dwarf2
endif
>>>>>>> a3be2c9e48354b0711658dbdd9284850fed3922c

all: test lib

test: test.o hw_sprintf.o
	g++ $(CXXFLAGS) -o $@ $^

lib: hw_sprintf.o
	ar rcs libhw.a $^

%.o: %.asm
	yasm $(YFLAGS) -o $@ $^

clean:
	rm -f *.o test
