#include "hw1.h"

#include <cstdio>
#include <limits>

using namespace std;

int main() {
    char out[100];
    hw_sprintf(out, "x = %%wtfd!\n", -50);
    printf("%s", out);
    return 0;
}