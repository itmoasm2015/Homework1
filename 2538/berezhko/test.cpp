#include "include/hw1.h"
#include <iostream>
#include <cstdio>
#include <cstring>
#include <cassert>

using namespace std;

char out[2000000];

bool myStrCmp(const char *s1, const char *s2) {
    if (strlen(s1) != strlen(s2)) return false;
    int len = strlen(s1);
    for (int i = 0; i < len; i++) {
        if (s1[i] != s2[i]) {
            return false;
        }
    }
    return true;
}

void test() {
    hw_sprintf(out, "Hello world %d", 239);
    assert(myStrCmp(out, "Hello world 239") == true);

    hw_sprintf(out, "%8u=%-8u", 1234, 1234);
    assert(myStrCmp(out, "    1234=1234    ") == true);

    hw_sprintf(out, "%llu", (long long)-1);
    assert(myStrCmp(out, "18446744073709551615") == true);

    hw_sprintf(out, "%+5u", 51);
    assert(myStrCmp(out, "  +51") == true);
    hw_sprintf(out, "%+5d", 51);

    assert(myStrCmp(out, "  +51") == true);

    hw_sprintf(out, "%wtf", 1, 2, 3, 4);
    assert(myStrCmp(out, "%wtf") == true);

    hw_sprintf(out, "50%%");
    assert(myStrCmp(out, "50%") == true);

    hw_sprintf(out, "%ll %d", 123);
    assert(myStrCmp(out, "%ll 123") == true);

    hw_sprintf(out, "50%%");
    assert(myStrCmp(out, "50%") == true);

    hw_sprintf(out, "%lld", -17LL);
    assert(myStrCmp(out, "-17") == true);

    hw_sprintf(out, "%+-+--+d %+8ii", 123, -4324);
    assert(myStrCmp(out, "+123    -4324i") == true);

    hw_sprintf(out, "%lld", 1152921504606846975);
    assert(myStrCmp(out, "1152921504606846975") == true);

    hw_sprintf(out, "% l%d", 123);
    assert(myStrCmp(out, "% l123") == true);

    hw_sprintf(out, "%-%%d", 123);
    assert(myStrCmp(out, "%123") == true);

    // Segfault test:
    hw_sprintf(out, "%1000000d", 123000);
    hw_sprintf(out, "%+10-0000d", 123000);
    hw_sprintf(out, "%01000000d", 12);
    hw_sprintf(out, "%d%%%d%u%i%d%lldsdfhj3jk5jk3jk4b1jk34bk1jk13b   \t\n\r34234l2kj3lrkl23", 1,2,3,4,5,6,7,8,9);
}

int main() {
    test();
    return 0;
}


