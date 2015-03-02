yasm -f elf32 -g dwarf2 -o hw_sprintf.o hw_sprintf.asm
g++ -std=c++11 -m32 -c test.cpp
g++ -m32 -o test hw_sprintf.o test.o
rm hw_sprintf.o
rm test.o
./test
rm test
