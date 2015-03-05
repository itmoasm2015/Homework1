//#include "hw1.h"
#include <stdio.h>

void hw_sprintf(char *out, char const *format, ...);

int compare(const char * a, const char * b)
{
    int i = 0;
    while (a[i] != 0) {
        if (a[i] != b[i])
            return 0;
        i++;
    }
    return 1;
}

int verbose = 0;

int test(const char* s, int aa, int bb, int cc)
{
    char a[1000], b[1000];

    hw_sprintf(a, s, aa, bb, cc);
    sprintf(b, s, aa, bb, cc);
    if (compare(a, b) == 0) {
        //if (verbose) 
            printf("Test failed:\n%s\n%s\n", b, a);
        //else 
        //    printf("FAILED\n");
    } else {
        if (verbose)
            printf("Test OK:     \n%s\n\n", a);
        else
            printf("OK\n");
    }
}

int expect(const char* ex, const char * s, int aa, int bb, int cc) 
{
    char a[1000];
    
    hw_sprintf(a, s, aa, bb, cc);
    if (compare(a, ex) == 0) {
        //if (verbose) 
            printf("Test failed:\n%s\n%s\n", ex, a);
        //else 
        //    printf("FAILED\n");
    } else {
        if (verbose)
            printf("Test OK:     \n%s\n\n", a);
        else
            printf("OK\n");
    }
}

int main()
{

    test("lalka: %0+24u ololo", 42, 0, 0);
    expect("lalka: %0+24-llu ololo", "lalka: %0+24-llu ololo", 42, 0, 0);
    test("lalka: %0% ololo", 42, 0, 0);
    test("lalka: %u ololo", 69, 0, 0);
    test("lalka: %+u ololo", 78, 0, 0);
    test("lalka: %+u ololo", -1, 0, 0);
    test("lalka: %+u %++u %0+++u ololo", -1, -2, -3);
    test("lalka: %0u %u ololo", 12, 54, 0);
    test("lalka: %u=%+-u ololo", 12, 54, 0);
    test("lalka: %u=%-u ololo", 12, 54, 0);
    test("lalka: %-u=%u ololo", 12, 54, 0);
    test("lalka: % u ololo", 12, 0, 0);
    test("lalka: % 0u%% ololo", 12, 0, 0);
    test("lalka: %d ololo", -42, 0, 0);
    test("lalka: %d ololo", 0x80000000, 0, 0);
    test("lalka: %+d ololo", -42, 0, 0);    
     test("lalka: %0+24d ololo", 42, 0, 0);
    test("lalka: %0% ololo", 42, 0, 0);
    test("lalka: %d ololo", 69, 0, 0);
    test("lalka: %+d ololo", 78, 0, 0);
    test("lalka: %+d ololo", -1, 0, 0);
    test("lalka: %+d %++d %0+++d ololo", -1, -2, -3);
    test("lalka: %0d %d ololo", -12, -54, 0);
    test("lalka: %d=%+-d ololo", -12, 54, 0);
    test("lalka: %d=%-d ololo", -12, -54, 0);
    test("lalka: %-d=%d ololo", -12, -54, 0);
    test("lalka: % d ololo", -12, 0, 0);
    test("lalka: % 0d%% ololo", -12, 0, 0);

    return 0;
}
