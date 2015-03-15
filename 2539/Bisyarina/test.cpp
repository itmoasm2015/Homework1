#include <hw1.h>

#include <cstdio>
#include <cstring>
#include <limits>

using namespace std;
char out[1000010];
char exp[1000001];
char act[1000001];

#define disable_test(...)

#define test(args...) { hw_sprintf(act, args); sprintf(exp, args); \
		if (strcmp(exp, act)) fprintf(stderr, "Error: %s, expected: %s, but got %s\n", "'" #args "'", exp, act); \
		else fprintf(stderr, "OK\n");}

int main() {
	
	test("%d", 5);
	test("%+u", 239);
	test("%+-010d=\n", 123);
	test("%ll%d\n", (long long) 123);
	disable_test("%ll10d\n", (long long) 123);
	test("%+10lld\n", (long long) 123);
	test("%+10-0000d\n", 123);
	test("%50-%=\n");
	test("%-10%=\n");
	test("%%%d\n", 123);
	test("50%%\n");
	test("%wtf\n", 1, 2, 3, 4);
	test("%lli\n", (long long)-1);
	test("%llu\n", (long long)-2);
	test("<%12i=%-12u>\n", -1, -1);
	test("<% 12u=%- 12i>\n", 1234, numeric_limits<int>::min());
	test("<% 12u\n", 1234);
	test("Hello world %d!\n", 239);
	test("%0+5d\n", 51);
	disable_test("% l%d", 239);
	test("% +d!\n", 239);
	test("%1000000d", 239);
	test("%-%%d", 239);
	disable_test("%ll %d", 239);
	
	test("%01000000d", 239);
	test("%01000000d", -239);
	test("%+-1000000d", 239);
	test("%+01000000d", 239);
	test("%+1000000d", 239);
	test("%-+1000000d", 239);
	test("%-+1000000d", -239);
    return 0;
}
