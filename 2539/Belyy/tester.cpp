#include <hw1.h>
#include <stdio.h>

int main() {
    char out[256];
    hw_sprintf(out, "Hello world %d!\n", 239);
    printf("%s", out);
    hw_sprintf(out, "%0+5d\n", 51);
    printf("%s", out);
    hw_sprintf(out, "<%8d=%-8d>\n", 1234, 5678);
    printf("%s", out);
    // TODO : fix
    //hw_sprintf(out, "%d\n", -1);
    //printf("%s", out);
    hw_sprintf(out, "%wtf\n");
    printf("%s", out);
    hw_sprintf(out, "50%%\n");
    printf("%s", out);
    return 0;
}
