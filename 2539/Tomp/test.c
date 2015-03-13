#include "stdio.h"
#include "unistd.h"
#include "string.h"
#include "../../include/hw1.h"

char buf[30];

#define test(...) hw_sprintf(buf, __VA_ARGS__); printf("%s|\n", buf)

int main() {
    test("%+10-0000d");
    test("%ll %d", 123);
    test("%-%%d", 123);
    test("% l%d", 123);
    return 0;
}
