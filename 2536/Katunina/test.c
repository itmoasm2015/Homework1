#include <string.h>
#include <stdio.h>
#include "../../include/hw1.h"

char out[4096];

#define test(...) hw_sprintf(out, __VA_ARGS__); printf("%s|\n", out)

int main() {

    test( "Hello world %d", 239);
    test( "%+5u", 51);
    test("%8u=%-8u", 1234, 1234);
    test( "%llu", (long long)-1);
    test("%wtf", 1, 2, 3, 4);
    test( "50%%");
    test("%" "+" "-"         "30" "ll" "d", (long long)-45);
    test("%"     "-"     " " "30" "ll" "u", (long long)-45);
    test("%"         "0" " " "30" "ll" "u", (long long) 45);
    test("%4d%8d%-8d", 12432, 123, 234);
        return 0;
}
