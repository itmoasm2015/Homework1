ASM = yasm
ASFLAGS = -f elf32

CFLAGS = -g -Wall -m32
CC = gcc

EXECUTABLE = main
LIBHW = libhw

all: $(EXECUTABLE)

clean:
	rm -f $(LIBHW).o
	rm -f $(LIBHW).a
	rm -f $(EXECUTABLE).o
	rm -f $(EXECUTABLE) 

$(EXECUTABLE): $(LIBHW).a $(EXECUTABLE).o
	$(CC) $(CFLAGS) $(EXECUTABLE).cpp $(LIBHW).a -o $@

$(EXECUTABLE).o:
	$(CC) $(CFLAGS) -c $(EXECUTABLE).cpp -o $@

$(LIBHW).a: $(LIBHW).o
	ar rcs $@ $<

$(LIBHW).o: hw_sprintf.asm
	$(ASM) $(ASFLAGS) $< -o $@ 