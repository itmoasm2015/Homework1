yasm -fwin32 hw.asm -o hw.o && gcc -m32 -std=c99 test.c hw.o -o a.exe
