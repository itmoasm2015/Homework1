#include "stdio.h"
#include "unistd.h"
#include "string.h"
#include "../../include/hw1.h"

char buf[30];

int main() {
    hw_sprintf(buf, "Some magic output =%-+0 20d", (int)-32767);
    write(1, buf, strlen(buf));
    return 0;
}
