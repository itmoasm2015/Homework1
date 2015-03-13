#include "stdio.h"
#include "unistd.h"
#include "string.h"

void ullformat(char *fmt, char *dest, ...);

void ulltoa(unsigned long long number, char *dest);

char buf[30];

int main() {
    ullformat("%-+0 20d", buf, (int)-32767);
    //ulltoa(-2, buf);
    write(1, buf, strlen(buf));
    return 0;
}
