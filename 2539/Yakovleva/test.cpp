#include "hw1.h"
#include <stdio.h>

char out[10000];

int main() {
    printf("START TEST\n");
    hw_sprintf(out, "Hello world %ll %+d!\n", 12345676543, 53);
    printf("RESULT=%s\n", out);
    return 0;
}

