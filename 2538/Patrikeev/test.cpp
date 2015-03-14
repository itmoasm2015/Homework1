#include "hw1.h"
#include <stdio.h>
#include <string.h>
#include <memory.h>

int main() {

    char out[256];
 //   hw_sprintf(out, "Hello, I am a cool string!!!!!!!!!");
    memset(out, 0, sizeof(out));
    hw_sprintf(out, "% 10d");


    for (int i = 0; i < 50; i++) {
        printf("%d ", out[i]);
    }

    return 0;
}
