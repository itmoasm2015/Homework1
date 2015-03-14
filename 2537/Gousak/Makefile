ASM = yasm
ASFLAGS = -f elf32

CFLAGS = -Wall -Werror -m32

EXECUTABLE = main
LIBHW = libhw

all: $(EXECUTABLE)

debug: CFLAGS += -g
debug: ASFLAGS += -g dwarf2
debug: $(EXECUTABLE)

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
