#include <hw1.h>

#include <cstdio>
#include <limits>

using namespace std;

int main() {
	char out[256];

	hw_sprintf(out, "Hello, world!\n");
	printf("%s", out);

	hw_sprintf(out, "%wtf\n");
	printf("%s", out);

	hw_sprintf(out, "50%%\n");
	printf("%s", out);

	hw_sprintf(out, "%-10%=\n");
	printf("%s", out);

	hw_sprintf(out, "%50-%=\n");
	printf("%s", out);

	hw_sprintf(out, "%ll%d\n");
	printf("%s", out);
}
