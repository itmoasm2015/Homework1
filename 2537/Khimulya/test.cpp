#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include "hw1.h"

const int BUFFER_SIZE = 4096;

bool test(const char *hw, const char *std, bool verbose) {
    bool match;
    if ((match = !strcmp(hw, std)) == false) {
        printf("Test failed\n");
    } else {
        printf("Test OK\n");
    }
    if (verbose || !match) {
        printf("\tsprintf:    %s\n", std);
        printf("\thw_sprintf: %s\n", hw);
    }

    return match;
}

int main(int argc, char *argv[]) {
    // first argv is working dir
    bool verbose = argc >= 2 && !strcmp(argv[1], "-v");
    char *buffer = new char[BUFFER_SIZE];
    char *hw_buffer = new char[BUFFER_SIZE];

    hw_sprintf(hw_buffer, "%d == %d", 2147483648, -2147483648);
    sprintf(buffer, "%d == %d", 2147483648, -2147483648);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%ud", 2147483648);
    sprintf(buffer, "%ud", 2147483648);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%d", 2147483647);
    sprintf(buffer, "%d", 2147483647);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%u", -1);
    sprintf(buffer, "%u", -1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%01u", -1);
    sprintf(buffer, "%01u", -1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%01-u", -1);
    sprintf(buffer, "%01-u", -1);
    test(hw_buffer, buffer, verbose);

	return 0;
}
