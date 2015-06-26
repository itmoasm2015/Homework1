#include <hw1.h>

#include <cstdio>
#include <limits>

using namespace std;

int main() {
    char out[256];
    hw_sprintf(out, "Hello world %d!\n", 239);
    printf("%s", out);
    hw_sprintf(out, "%0+5d\n", 51);
    printf("%s", out);
    hw_sprintf(out, "<%12u=%-12i>\n", 1234, numeric_limits<int>::min());
    printf("%s", out);
    hw_sprintf(out, "<%12i=%-12u>\n", -1, -1);
    printf("%s", out);
    hw_sprintf(out, "%llu\n", (long long)-2);
    printf("%s", out);
    hw_sprintf(out, "%lli\n", (long long)-1);
    printf("%s", out);
    hw_sprintf(out, "%wtf\n", 1, 2, 3, 4);
    printf("%s", out);
    hw_sprintf(out, "50%%\n");
    printf("%s", out);
    hw_sprintf(out, "%%%d\n", 123);
    printf("%s", out);
    hw_sprintf(out, "%-10%=\n");
    printf("%s", out);
    hw_sprintf(out, "%50-%=\n");
    printf("%s", out);
    hw_sprintf(out, "%+10-0000d\n", 123);
    printf("%s", out);
    hw_sprintf(out, "%10lld\n", (long long) 123);
    printf("%s", out);
    hw_sprintf(out, "%ll10d\n", (long long) 123);
    printf("%s", out);
    hw_sprintf(out, "%ll%d\n", (long long) 123);
    printf("%s", out);
    sprintf(out, "%ll%d\n", (long long) 123);
    printf("%s", out);
    hw_sprintf(out, "%+-010d=\n", 123);
    printf("%s", out);
    return 0;
}