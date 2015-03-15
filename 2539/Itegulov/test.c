#include "hw1.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <limits.h>
#include <assert.h>

int main() {
    char buf[1024];
    int res;
    hw_itoa(-15, buf);
    assert(strcmp(buf, "-15") == 0);
    hw_itoa(20, buf);
    assert(strcmp(buf, "20") == 0);
    hw_itoa(0, buf);
    assert(strcmp(buf, "0") == 0);
    res = hw_itoa(29384723, buf);
    assert(res == 8);
    assert(strcmp(buf, "29384723") == 0);
    res = hw_itoa(-2384722, buf);
    assert(res == 8);
    assert(strcmp(buf, "-2384722") == 0);
    res = hw_ultoa(1, buf);
    assert(res == 1);
    assert(strcmp(buf, "1") == 0);
    res = hw_ultoa(34857693450LL, buf);
    assert(res == 11);
    assert(strcmp(buf, "34857693450") == 0);
    res = hw_ltoa(LLONG_MIN, buf);
    char buf2[1024];
    snprintf(buf2, 1024, "%lld", LLONG_MIN); 
    assert(strcmp(buf, buf2) == 0);

    hw_format(buf, "-123", 0, 10);
    assert(strcmp(buf, "      -123") == 0);

    hw_format(buf, "3248753847", 0, 5);
    assert(strcmp(buf, "3248753847") == 0);
    
    hw_format(buf, "384", 4, 5);
    assert(strcmp(buf, " +384") == 0);

    hw_format(buf, "384", 8, 3);
    assert(strcmp(buf, " 384") == 0);

    hw_format(buf, "82934", 32, 10);
    assert(strcmp(buf, "82934     ") == 0);

    hw_sprintf(buf, "Hello World %d", 239);
    assert(strcmp(buf, "Hello World 239") == 0);

    hw_sprintf(buf, "%+5u", 51);
    assert(strcmp(buf, "  +51") == 0);

    hw_sprintf(buf, "%8u=%-8u", 1234, 1234);
    assert(strcmp(buf, "    1234=1234    ") == 0);

    hw_sprintf(buf, "%llu", (long long)-1);
    assert(strcmp(buf, "18446744073709551615") == 0);

    hw_sprintf(buf, "%+10-0000d", 123);
    assert(strcmp(buf, "%+10-0000d") == 0);

    hw_sprintf(buf, "% l%d", 123);
    assert(strcmp(buf, "% l123") == 0);

    hw_sprintf(buf, "%wtf", 1, 2, 3, 4);
    assert(strcmp(buf, "%wtf") == 0);

    hw_sprintf(buf, "50%%");    
    assert(strcmp(buf, "50%") == 0);

    hw_sprintf(buf, "%wtf 50%% %+5u", 51);
    assert(strcmp(buf, "%wtf 50%   +51") == 0);

    hw_sprintf(buf, "%ll %d", 123);
    assert(strcmp(buf, "%ll 123") == 0);

    hw_sprintf(buf, "%-%%d", 123);
    assert(strcmp(buf, "%123") == 0);

    hw_sprintf(buf, "%lld", -17LL);
    assert(strcmp(buf, "-17") == 0);

    printf("OK\n");

    return 0;
}
