#include "hw1.h"
#include <cstdio>
#include <iostream>
#include <string>
#include <cstring>
#include <cstdlib>

using namespace std;

char out[1000000];
char ans[1000000];

void check(char* out, char* ans)
{
    string s = (const char*) out;
    string t = (const char*) ans;

    if (s == t)
        return;

    printf("Expected: \"%s\"; found: \"%s\"\n", ans, out);
    exit(0);
}

int main ()
{
    hw_sprintf(out, "%10-0000d", 1);
    sprintf(ans, "%10-0000d", 1);
    check(out, ans);

    hw_sprintf(out, "Hello world%d", 239);
    sprintf(ans, "Hello world%d", 239);
    check(out, ans);

    hw_sprintf(out, "%8u=%-8u", 1234, 1234);
    sprintf(ans, "%8u=%-8u", 1234, 1234);
    check(out, ans);

    hw_sprintf(out, "%llu", (long long) -1);
    sprintf(ans, "%llu", (long long) -1);
    check(out, ans);

    hw_sprintf(out, "%wtf", 1, 2, 3, 4);
    sprintf(ans, "%wtf", 1, 2, 3, 4);
    check(out, ans);

    hw_sprintf(out, "50%%", 1);
    sprintf(ans, "50%%", 1);
    check(out, ans);

    printf("All tests passed\n");

    return 0;
}
