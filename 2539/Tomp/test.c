#include "stdio.h"
#include "unistd.h"
#include "string.h"

void ullformat(char *fmt, char *dest, ...);

void ulltoa(unsigned long long number, char *dest);

char buf[30];

int main() {
    ullformat("% +50d", buf, (int)-65536);
    //ulltoa(-2, buf);
    write(1, buf, strlen(buf));
    return 0;
}
