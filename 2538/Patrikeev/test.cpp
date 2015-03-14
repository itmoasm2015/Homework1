#include "hw1.h"
#include <stdio.h>
#include <string.h>
#include <memory.h>

int main() {
    char out[256];
    memset(out, 0, sizeof(out));

    hw_sprintf(out, "Hello %d xyz %u %f", (unsigned long long) 283686952306183);
    
    printf("\n%+010d|\n", 10);



    return 0;
}
