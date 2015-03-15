#include "hw1.h"
#include <stdio.h>
#include <string.h>
#include <memory.h>

int main() {

    char out[256];

    memset(out, 0, sizeof(out));
    
    hw_sprintf(out, "%+-10llu", (unsigned long long) 10);
    

    for (int i = 0; i < 50; i++) {
        printf("%c ", out[i]);
    }

    return 0;
}
