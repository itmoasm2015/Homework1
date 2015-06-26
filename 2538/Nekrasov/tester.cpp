#include <hw1.h>

#include <cstdio>
#include <limits>

using namespace std;

int main() {
	char out[256];
	
	printf("Hello!\n");
	hw_sprintf(out, "Hello world!\n");
	printf("%s", out);
}
