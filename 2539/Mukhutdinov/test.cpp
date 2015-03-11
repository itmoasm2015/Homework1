#include <cassert>
#include <cstring>
#include <iostream>
#include "hw1.h"

int main() {
    char buf[16];
    hw_uitoa(10, buf);
    assert(strcmp(buf, "10") == 0);
    hw_uitoa(123123, buf);
    assert(strcmp(buf, "123123") == 0);
    hw_itoa(-100500, buf);
    assert(strcmp(buf, "-100500") == 0);
    return 0;
}
