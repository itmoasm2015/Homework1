#include <cassert>
#include <cstdio>
#include <cstring>
#include <iostream>
#include "hw1.h"

#define TEST(count, total, format, ...) {                               \
        char str[1000], str2[1000];                                     \
        sprintf(str, format, __VA_ARGS__);                              \
        hw_sprintf(str2, format, __VA_ARGS__);                          \
        printf("Test #%d result: %s\n", total + 1, str2);               \
        int rs = !strcmp(str, str2);                                    \
        if(!rs) {                                                       \
            printf("Miserable fail with %s " format " \n", format, __VA_ARGS__); \
            printf("sprintfy makes      %s %s \n", format, str);        \
            printf("Got instead         %s %s \n\n", format, str2);     \
        }                                                               \
        count += rs;                                                    \
        total++;                                                        \
    }

int main() {
    char buf[24];
    int a = 10;
    hw_ntoa(&a, buf, 0, 0);
    assert(strcmp(buf, "10") == 0);
    a = 123123;
    hw_ntoa(&a, buf, 0, 10);
    assert(strcmp(buf, "    123123") == 0);
    hw_ntoa(&a, buf, 1, 10);
    assert(strcmp(buf, "   +123123") == 0);
    hw_ntoa(&a, buf, 8, 10);
    assert(strcmp(buf, "0000123123") == 0);
    hw_ntoa(&a, buf, 9, 10);
    assert(strcmp(buf, "+000123123") == 0);
    hw_ntoa(&a, buf, 4, 10);
    assert(strcmp(buf, "123123    ") == 0);
    a = -100500;
    hw_ntoa(&a, buf, 0, 10);
    assert(strcmp(buf, "   -100500") == 0);

    long long b = 456456456456456;
    hw_ntoa(&b, buf, 16, 0);
    assert(strcmp(buf, "456456456456456") == 0);
    hw_ntoa(&b, buf, 18, 0);
    assert(strcmp(buf, " 456456456456456") == 0);
    b = -456456456456456;
    hw_ntoa(&b, buf, 16, 0);
    assert(strcmp(buf, "-456456456456456") == 0);

    int count = 0, total = 0;

    TEST(count, total, "Hello world %d", 239);
    TEST(count, total, "%5u", 51);
    TEST(count, total, "%8u=%-8u", 1234, 1234);
    TEST(count, total, "%llu", (long long) -1);
    TEST(count, total, "%wtf", 1, 2, 3, 4);
    TEST(count, total, "50%%", 0);

    return 0;
}
