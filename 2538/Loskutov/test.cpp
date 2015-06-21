#include <cstdio>
#include <string.h>
#include <limits.h>
#include "test.h"
bool failed = false;
#define test_equals(correct, format, ...) \
    do { \
        hw_sprintf(out2, format, __VA_ARGS__); \
        if (strcmp(correct, out2) == 0) printf("%-30s: %s", format, "\e[0;32mOK\e[0m\n"); \
        else { \
            failed = true; \
            printf("format string \"%s\"\n", format); \
            printf("\"%s\" expected\n", correct); \
            printf("\"%s\" actually\n", out2); \
            puts("\e[4;31mFAIL\e[0m"); \
            puts(""); \
        } \
    } while (0)

#define test(...) \
    do { \
        sprintf(out1, __VA_ARGS__); \
        test_equals(out1, __VA_ARGS__); \
    } while(0)

int main() {
    char out1[1005000];
    char out2[1005000];
    test("%+10-0000d", 123);
    test_equals("% l123", "% l%d", 123);
    test_equals("%ll 123", "%ll %d", 123);
    test("%-%%d", 123);
    test("Hello world %d", 239);
    test_equals("  +51", "%+5u", 51);
    test("%8u=%-8u", 1234, 1234);
    test("%80u", 1234, 1234LL);
    test("%wtf", 123);
    test("%01000000d", 123);
    test("%-08d", 123);
    test("%+ 05000lld%% papirosim", -2228888888888LL);
    test("%+050d%% papirosim", 228);
    test("228 papirosim", 123);
    test("%d papirosim", 228);
    test("%d", 123);
    test_equals("%  ", "%  ", 10);
    test("%lld", -17);
    test("%+-+-    -+d %         +8ii", 123, -4324);
    test("%d%%%d%u%i%d%lldsdfhj3jk5jk3jk4b1jk34bk1jk13b   \t\n\r34234l2kj3lrkl23", 123, 123, 123, 123, 123, 123LL);
    return failed;
}
