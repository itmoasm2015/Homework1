
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
    printf("\n Make completed. Testing ...  \n \n");
	ok("%"); test("%+++ll%");
	ok("I believe that my points on the android development will be more than 60"); test("I believe that my points on the android development will be more than %d", 60);
    ok("+00000000000000000000000000777"); test("%" "+"     "0"     "30" "ll" "d", (long long) 777);
    ok("%+33-0000d"); test("%+33-0000d");
    ok("-268435456"); test("%d", -268435456);
    ok(" +777"); test("%+5u", 777);
    ok("     777=777     "); test("%8u=%-8u", 777, 777);
    ok("%ll 777"); test("%ll %d", 777);
    ok("%777"); test("%-%%d", 777);
    ok("% l777"); test("% l%d", 777);
    ok("+0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000777"); test("%+0200u", 777);
    ok("%azaz"); test("%azaz", 11, 77, 11, 77, 11, 77, 11, 77, 11, 77);
    ok("777%"); test("777%%");
    ok("-777                          "); test("%" "+" "-" "0"     "30" "ll" "d", (long long)-777);
    ok("%wtf"); test("%wtf");
    if (failed) {
		if (failed > 1) end = 's';
		printf("\n %d test%c failed \n", failed, end);
	} else {
		printf("\n All tests passed \n");
	}
    return 0;
}
