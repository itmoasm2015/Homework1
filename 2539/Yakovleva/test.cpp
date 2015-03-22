#include "hw1.h"
#include <stdio.h>

char out[10000];

int main() {
    printf("START TEST\n");
//    hw_sprintf(out, "Hello world !%7d!% 10d!\n", 12567, -4234853);
//    hw_sprintf(out, "Hello world %d", 239);
//    "Hello world 239"
//    hw_sprintf(out, "%+5u", 51);
//    "  +51"
//    hw_sprintf(out, "%8u=%-8u", 1234, 1234);
//    "    1234=1234    "
//-    hw_sprintf(out, "%llu", (long long)-1);
//    "18446744073709551615"
//    hw_sprintf(out, "%wtf", 1, 2, 3, 4);
//    "%wtf"
//    hw_sprintf(out, "50%%");
//    "50%"
    printf("RESULT=!%s!\n", out);
    return 0;
}

