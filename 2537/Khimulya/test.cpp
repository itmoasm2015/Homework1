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

    hw_sprintf(hw_buffer, "%d", -1);
    sprintf(buffer, "%d", -1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%01-u%d", -1, 1);
    sprintf(buffer, "%01-u%d", -1, 1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%%%d", 0);
    sprintf(buffer, "%%%d", 0);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "% d % d", 100, -100);
    sprintf(buffer, "% d % d", 100, -100);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "% d %+d", 100, 100);
    sprintf(buffer, "% d %+d", 100, 100);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "% d %+ d", 100, 100);
    sprintf(buffer, "% d %+ d", 100, 100);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%10d %010u", 0, 111);
    sprintf(buffer, "%10d %010u", 0, 111);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%10d %-10u", 0, 111);
    sprintf(buffer, "%10d %-10u", 0, 111);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%2d %3d", -1, -1);
    sprintf(buffer, "%2d %3d", -1, -1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "% -5d", 100);
    sprintf(buffer, "% -5d", 100);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%2d %03d", -1, -1);
    sprintf(buffer, "%2d %03d", -1, -1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%2i %03i", -1, -1);
    sprintf(buffer, "%2i %03i", -1, -1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%2d % 04d", -1, -1);
    sprintf(buffer, "%2d % 04d", -1, -1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "% 4d % 4d", -1, 1);
    sprintf(buffer, "% 4d % 4d", -1, 1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%8u=%-8u", 1234, 1234);
    sprintf(buffer, "%8u=%-8u", 1234, 1234);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%llu", (long long)-1);
    sprintf(buffer, "%llu", (long long)-1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%llu", (long long)1 << 32 - 1);
    sprintf(buffer, "%llu", (long long)1 << 32 - 1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%llu", (long long)2 << 33 - 1);
    sprintf(buffer, "%llu", (long long)2 << 33 - 1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%lld", -((long long)1 << 32 - 1));
    sprintf(buffer, "%lld", -((long long)1 << 32 - 1));
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%lld", (long long)-1);
    sprintf(buffer, "%lld", (long long)-1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%020lld", (long long)-1);
    sprintf(buffer, "%020lld", (long long)-1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%lld %llu", -(long long)1, -(long long)1);
    sprintf(buffer, "%lld %llu", -(long long)1, -(long long)1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%+10-0000d", -1);
    sprintf(buffer, "%+10-0000d", -1);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%10lld %-10llu", (long long)0, (long long)111);
    sprintf(buffer, "%10lld %-10llu", (long long)0, (long long)111);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%10lli %-10lli", (long long)0, (long long)111);
    sprintf(buffer, "%10lli %-10lli", (long long)0, (long long)111);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%-%%d", 123);
    sprintf(buffer, "%-%%d", 123);
    test(hw_buffer, buffer, verbose);

    hw_sprintf(hw_buffer, "%-00-%%d % -010% %-0 10lli", 123, (long long)321);
    sprintf(buffer, "%-00-%%d % -010% %-0 10lli", 123, (long long)321);
    test(hw_buffer, buffer, verbose);

	return 0;
}
