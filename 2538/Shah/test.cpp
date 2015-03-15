#include "hw1.h"
#include <stdio.h>
#include <limits>
#include <string.h>
#include <stdlib.h>

using namespace std;

extern void hw_sprintf(char* out, const char* format, ...);

char out[1000];
char out2[1000];

void check()
{
    printf("%s\n", out);
}


int main()
{
    hw_sprintf(out, "%%%%%%%");
    check();
    hw_sprintf(out, "%d=%u", -1, -1);
    check();
    hw_sprintf(out, "%+d=%0u", 1, 1);
    check();
    hw_sprintf(out, "%lld=%llu", 1, -1);
    check();
    hw_sprintf(out, "%lld=%llu", 1, -1);
    check();
    hw_sprintf(out, "%i %030u %+030i %030llu % 030lld", 10, -1, 1, -1ll, 1ll);
    check();
    hw_sprintf(out, "%i %0-20lld", 10, -1ll);
    check();
    hw_sprintf(out, "%+10-0000d", -1);
    check();
    hw_sprintf(out, "%wtf", 1, 2, 3, 4);
    check();
    hw_sprintf(out, "%+5u", 51);
    check();
    hw_sprintf(out, "%8u=%-8u", 1234, 1234);
    check();
    hw_sprintf(out, "%llu", (long long)-1);
    check();
    hw_sprintf(out, "50%%%%");
    check();
    return 0;
}
