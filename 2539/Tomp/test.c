#include "stdio.h"
#include "unistd.h"
#include "string.h"
#include "../../include/hw1.h"

char buf[1000];

#define test(...) hw_sprintf(buf, __VA_ARGS__); printf("%s|\n", buf)

int main() {
    test("%+10-0000d");
    test("%ll %d", 123);
    test("%-%%d", 123);
    test("% l%d", 123);
    test("%+0200u", 123);
    test("Hello world %d", 239);
    test("%+5u", 51);
    test("%8u=%-8u", 1234, 1234);
    test("%wtf", 1, 2, 3, 4);
    test("50%%");
    test("A bigger test:\n\t* some integer %0+5d|\n\t* unsigned %0-30u", (int)-65535, (int)-32767);
    test("\t* some long integer %0 10lld|\n\t* unsigned long long %30llu", (long long)-65535, (long long)-32767);
    return 0;
}
