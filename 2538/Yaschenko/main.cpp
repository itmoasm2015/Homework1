#include "hw1.h"

#include <cstdio>
#include <limits>

using namespace std;

int main() {
    char out[100];
    hw_sprintf(out, "%d %d", 543, 111111);
    printf("%s", out);
    return 0;
}
