#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "hw1.h"



int main(int argc, char *argv[]) {
    char *char_array = new char[2048];

    hw_sprintf(char_array, "%d == %d", 52);
    printf("%s\n",char_array);

    hw_sprintf(char_array, "%ud", 42);
    printf("%s\n",char_array);

    hw_sprintf(char_array, "%d", -38);
    printf("%s\n",char_array);

    hw_sprintf(char_array, "%u", -1);
    printf("%s\n",char_array);

    hw_sprintf(char_array, "%01u", -1);
    printf("%s\n",char_array);

    return 0;
}
