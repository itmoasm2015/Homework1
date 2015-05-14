#include "hw1.h"
#include <stdio.h>

char out[10000];

int main() {
    printf("START TEST\n");
//    hw_sprintf(out, "Hello world !%7d!% 10d!\n", 12567, -4234853);
//    printf("RESULT=!%s!\n", out);
//    hw_sprintf(out, "Hello world !%lld!% 10d!\n", -42949672976, -4234853);
//    printf("RESULT=!%s!\n", out);
//    hw_sprintf(out, "Hello world !%lld!% 10d!", 10000000000000, -4234853);
//    printf("RESULT=!%s!\n", out);
//    hw_sprintf(out, "Hello world !%lld!% 10d!", -100000000000000, -4234853);
//    printf("RESULT=!%s!\n", out);
//    hw_sprintf(out, "Hello world %d", 239);
//    printf("RESULT=!%s!\n", out);
//    "Hello world 239"
//    hw_sprintf(out, "%+5u", 51);
//    printf("RESULT=!%s!\n", out);
//    "  +51"
//Test failed: "%lld" -> expected "1152921504606846975", got "+1152921500311879681"

    hw_sprintf(out, "%-08d", 123);
    printf("RESULT=!%s!\n", out);

    hw_sprintf(out, "%lld", -1152921504606846975);
    printf("RESULT=!%s!\n", out);

    hw_sprintf(out, "%-8u", 1234, 1234);
    printf("RESULT=!%s!\n", out);
//    "    1234=1234    "
    hw_sprintf(out, "%llu", (long long)-1);
    printf("RESULT=!%s!\n", out);
//    "18446744073709551615"
    hw_sprintf(out, "%wtf", 1, 2, 3, 4);
    printf("RESULT=!%s!\n", out);
//    "%wtf"
    hw_sprintf(out, "50%%");
    printf("RESULT=!%s!\n", out);
//    "50%"
    hw_sprintf(out, "%+++ll%", 12);
    printf("RESULT=!??%s!\n", out);
//    hw_sprintf(out, "%1000000i", 12);
//    printf("RESULT=!%s!\n", out);
    hw_sprintf(out, "%+10-0000d", 123);
    printf("RESULT=!%s!\n", out);
    return 0;
}

