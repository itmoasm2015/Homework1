#include "hw1.h"

#include <cstdio>
#include <stdio.h>
#include <string.h>
#include <limits>

using namespace std;

void accept(char* out) {
    printf("OK.(%s)\n", out);
}

void fail(char* out, char* check) {
    printf("FAIL. %s excepted, %s found", check, out);
}



void compare(char* out, char* check) {
    if (!memcmp(out, check, strlen(out))) {
        accept(out);
    } else fail (out, check);
}

int main() {
    char out[256];
    char check[256];
    unsigned int a = (int)+(int)-1;
    unsigned long long int b = (long long)+(long long)-1;
    hw_sprintf(out, "%u", a);
    sprintf(check, "%u", a);
    compare(out, check);
    hw_sprintf(out, "%llu", b);
    sprintf(check, "%llu", b);
    compare(out, check);
    hw_sprintf(out, "%5u",51);
    sprintf(check, "%5u",51);
    compare(out, check);
    hw_sprintf(out, "%8u=%-8u", 1234, 1234);
    sprintf(check, "%8u=%-8u", 1234, 1234);
    compare(out, check);
    hw_sprintf(out, "%llu",(long long)-1);
    sprintf(check, "%llu",(long long)-1);
    compare(out, check);
    hw_sprintf(out, "50%%");
    sprintf(check, "50%%");
    compare(out, check);
    hw_sprintf(out, "%lli", -11000000000);
    sprintf(check, "%lli", -11000000000);
    compare(out, check);
    hw_sprintf(out, "%llu", -11000000000);
    sprintf(check, "%llu", -11000000000);
    compare(out, check);
    return 0;
}


