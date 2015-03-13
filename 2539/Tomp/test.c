#include "stdio.h"

void ullformat(char *fmt, char *dest, ...);

void ulltoa(unsigned long long number, char *dest);

char buf[30];

int main() {
    ullformat("% %", buf, (int)-2);
    //ulltoa(-2, buf);
    printf("%s", buf);
    return 0;
}
