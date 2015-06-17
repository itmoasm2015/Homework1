#include "hw1.h"

#include <cstdio>
#include <stdio.h>
#include <string.h>
#include <limits>
#include <cstdarg>

using namespace std;

char out[1000001];
char check[1000001];


void accept(char* out) {
    printf("OK.(%s)\n", out);
}

void fail(char* out, char* check) {
    printf("FAIL. <%s> excepted, <%s> found\n", check, out);
}



void compare(char* out, char* check) {
    if (!memcmp(out, check, strlen(out))) {
        accept(out);
    } else fail (out, check);
}

void test(char const *buf) {
    hw_sprintf(out, buf, 123, 34342, 12243, 214244, 1242145);
    sprintf(check, buf, 123, 34342, 12243, 214244, 1242145);
    compare(out,check);
}

int main() {
    test("% % % %");
    test("string%%%%d");
    test("%0 5d");
    test("%d");
    test("%10d=");
    test("%+-010d=");
    test("%ll%d");
    test("%+10lld");
    test("%+10-0000d");
    test("%50-%=");
    test("%-10%=");
    test("%%%d");
    test("50%%");
    test("%lli");
    test("%llu");
    test("<%12i=%-12u>");
    test("<% 12u=%- 12i>");
    test("<% 12u");
    test("Hello world %d!");
    test("% -5d");
    test("%0+5d");
    test("%0+5d");
    test("% +d!");
    test("%10d");
    test("%-%%d");
    test("50%%");
    test("%010000d");
    return 0;
}


