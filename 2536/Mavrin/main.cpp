#include "hw1.h"

#include <cstdio>
#include <limits>

using namespace std;

int main() {
    char out[256];
    hw_sprintf(out, "50%%", 1234, 1234);	
    printf("%s", out);
    return 0;
}
