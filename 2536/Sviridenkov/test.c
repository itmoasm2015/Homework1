#include <stdio.h>
#include <string.h> 
#include "hw1.h"

#define size 4096

char result[size], expected[size], end;
int failed = 0, cur = 0;

void ok(char s[]){
    strcpy(expected, s);
    ++cur;
}

#define test(...) \
	hw_sprintf(result, __VA_ARGS__); \
	if (strcmp(result, expected)==0){ \
		printf("TEST %d PASSED \n", cur); \
	} else { \
		printf("TEST %d FAILED \n", cur); \
		failed++; \
	}; \

int main() {
    printf("\n Testing ...  \n \n");
	ok("%"); test("%+++ll%");
    ok("%+10-0000d"); test("%+10-0000d");
    ok("+00000000000000000000000000123"); test("%" "+"     "0"     "30" "ll" "d", (long long) 123);
    ok("%+33-0000d"); test("%+33-0000d");
    ok(" +123"); test("%+5u", 123);
    ok("     123=123     "); test("%8u=%-8u", 123, 123);
    ok("%ll 123"); test("%ll %d", 123);
    ok("%123"); test("%-%%d", 123);
    ok("% l123"); test("% l%d", 123);
    ok("+0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000123"); test("%+0200u", 123);
    ok("%azaz"); test("%azaz", 11, 77, 11, 77, 11, 77, 11, 77, 11, 77);
    ok("123%"); test("123%%");
    ok("-123                          "); test("%" "+" "-" "0"     "30" "ll" "d", (long long)-123);
    ok("%wtf"); test("%wtf");
    if (failed) {
		if (failed > 1) end = 's';
		printf("\n %d test%c failed \n", failed, end);
	} else {
		printf("\n All tests passed \n");
	}
    return 0;
}
