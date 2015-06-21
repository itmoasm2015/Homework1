
ASRC:= $(wildcard *.asm)
CSRC:=$(wildcard *.c)
CXXSRC:=$(wildcard *.cpp)

AOBJ:=$(ASRC:%.asm=obja/%.o)
COBJ:=$(CSRC:%.c=objc/%.o)
CXXOBJ:=$(CXXSRC:%.cpp=objcxx/%.o)



OS:=$(shell uname)


ifeq ($(OS), Darwin)
YASM_FLAGS=-f macho32 # mac os
else
YASM_FLAGS=-f elf32 -g dwarf2 # linux
endif


.PHONY: all clean
all: libhw.a 

clean:
	-rm $(AOBJ) $(COBJ) $(CXXOBJ)  main libhw.a

objc objcxx obja:
	-mkdir $@


objc/%.o: %.c  | objc
	gcc -std=c11 -c -m32 -g  -o $@ $<
objcxx/%.o: %.cpp |  objcxx
	g++ -std=c++11 -c -m32 -g -o $@ $<

obja/%.o: %.asm  | obja
	yasm $(YASM_FLAGS) -o $@ $<

libhw.a: $(AOBJ)
	ar rcs $@ $^

main:  $(COBJ) $(CXXOBJ) $(AOBJ)
	gcc -g -m32 $^  -o $@
