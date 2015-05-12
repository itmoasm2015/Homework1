#include <stdio.h>
#include "libhw.h"

#define test(args...) {\
    printf("testing: "); \
    puts(#args); \
    sprintf(a, args); \
    hw_sprintf(b, args);\
    if (strcmp(a, b) != 0) { \
        ok = 0; \
        puts("FAIL"); \
        puts("expected:"); \
        puts(a); \
        puts("found:"); \
        puts(b); \
    } else { \
        puts("OK"); \
    } \
}
    
const long long inf = (long long)(1e15);

int main() {
    char a[1000], b[1000];

    char ok = 1;

    test("d%d%%d", 135, 2);
    test("d%d%%d", -987, 2);
    test("%d", 1);
    test("%d %d", 1, 2);
    test("%lld", (long long)5);
    test("%llu", (unsigned long long)111111);
    test("%d %d %d", (int)0, (int)(inf), (int)(-inf));
    test("%lld %lld %lld", (long long)0, inf, -inf);
    test("%07d", 15);
    test("%+u", -1);

    if (ok) {
        puts("all tests passed");
    } else {
        puts("you have some errors");
    }

    return 0;
}
