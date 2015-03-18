CC=g++
CXXFLAGS=-std=c++1y -Wall -Wextra -m32 -g
PROJECT_NAME=test
OBJ=my_sprintf.o test.o hw_sprintf.o

all: $(OBJ)
	$(CC) -m32 $? -o $(PROJECT_NAME) 
	#ar rcs libhw.a hw_sprintf.o
	rm *.o

hw_sprintf.o: hw_sprintf.asm
	yasm -f elf32 -g dwarf2 $? -o $@

%.o: %.cpp
	$(CC) $(CXXFLAGS) -c $? -o $@

clean:
	rm $(PROJECT_NAME)

