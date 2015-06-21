#include "hw1.h"
#include <stdio.h>
#include <stdlib.h>

#include <string.h>
#include <assert.h>


char out[2000000];

void assert_equal(const char * s1, const char * s2)
{
    int c = strcmp(s1, s2);
    if(c != 0)
    {
        printf("!!! \"%s\"!=\"%s\"\n", s1, s2);
        //abort();
    }
    else
        printf("\"%s\"==\"%s\"\n", s1, s2);

}

void test() {
    hw_sprintf(out, "q%+06dz", 0);
    assert_equal(out, "q+00000z");

    hw_sprintf(out, "Hello world %d h", 239);
    assert_equal(out, "Hello world 239 h");

    hw_sprintf(out, "%lld", (long long)0x00ff00ff00ff00ff);
    assert_equal(out, "71777214294589695");

    hw_sprintf(out, "%llu", (long long)-1);
    assert_equal(out, "18446744073709551615");

    hw_sprintf(out, "%lld", (long long)-1);
    assert_equal(out, "-1");



    hw_sprintf(out, "%8u=%-8u", 1234, 1234);
    assert_equal(out, "    1234=1234    ");


    hw_sprintf(out, "%+5u", 51);
    assert_equal(out, "  +51");

    hw_sprintf(out, "%+5d", 51);
    assert_equal(out, "  +51");

    hw_sprintf(out, "%wtf", 1, 2, 3, 4);
    assert_equal(out, "%wtf");

    hw_sprintf(out, "50%%");
    assert_equal(out, "50%");

    hw_sprintf(out, "%ll %d", 123);
    assert_equal(out, "%ll 123");

    hw_sprintf(out, "50%%");
    assert_equal(out, "50%");

    hw_sprintf(out, "%lld", -17LL);
    assert_equal(out, "-17");

    hw_sprintf(out, "%+-+--+d %+8ii", 123, -4324);
    assert_equal(out, "+123    -4324i");

    hw_sprintf(out, "%lld", 1152921504606846975);
    assert_equal(out, "1152921504606846975");

    hw_sprintf(out, "% l%d", 123);
    assert_equal(out, "% l123");

    hw_sprintf(out, "%-%%d", 123);
    assert_equal(out, "%123");

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


