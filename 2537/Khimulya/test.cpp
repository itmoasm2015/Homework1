#include <stdio.h>
#include "itoa.h"

int main() {
	char *out = new char[11];
    itoa(-1234567890, out);
	printf("%s\n", out);
	return 0;
}
