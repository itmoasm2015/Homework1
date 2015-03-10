#include <stdio.h>
#include <string.h>
#include <string>
#include <stdarg.h>
#include "hw1.h"

const int BUFFER_SIZE = 4096;
char hw_buf[BUFFER_SIZE];
char buf[BUFFER_SIZE];

void test(std::string test) {
    if (strcmp(buf, hw_buf)) {
        printf("Test failed\n");
        printf("\tInput: ");
        printf("%s\n", test.c_str());
        printf("\tsprintf:    %s\n", buf);
        printf("\thw_sprintf: %s\n", hw_buf);
    } else {
        printf("Test OK\n");
    }
}

void run_test_of_2(const std::string format, int a1, int a2) {
    const char* tmp = format.c_str();
    hw_sprintf(hw_buf, tmp, a1, a2);
    sprintf(buf, tmp, a1, a2);
    test(format);
}

void run_test_of_1(const std::string format, int a1) {
    const char* tmp = format.c_str();
    hw_sprintf(hw_buf, tmp, a1);
    sprintf(buf, tmp, a1);
    test(format);
}

int main(int argc, char *argv[]) {
    run_test_of_2("%d == %d", 2147483648, -2147483648);
    run_test_of_1("%d", 2147483647);
    run_test_of_1("%u", -1);
    run_test_of_1("%01u", -1);
    run_test_of_2("%01-u%d", -1, 1);
    run_test_of_1("%%d", 0);
    run_test_of_2("% d % d", 100, -100);
    run_test_of_2("% d %+d", 100, 100);
    run_test_of_2("% d %+ d", 100, 100);
    run_test_of_2("%10d %010u", 0, 111);
    run_test_of_2("10d %-10u", 0, 111);
    run_test_of_2("%2d %3d", -1, -1);
    run_test_of_1("% -5d", 100);
    run_test_of_2("%2d %03d", -1, -1);
    run_test_of_2("%2d % 04d", -1, -1);
    run_test_of_2("% 4d % 4d", -1, 1);
    run_test_of_1("%llu", (long long) -1);
    run_test_of_1("%llu", (long long) 1 << 32 - 1);
    run_test_of_1("%llu", (long long) 2 << 33 - 1);
    run_test_of_1("%lld", - ((long long) 1 << 32 - 1));
    run_test_of_1("%lld", (long long) -1);
    return 0;
}
