#include "hw1.h"
#include <cstdio>

int main() 
{
    char s[100];
    for (int i = 0; i < 100; i++)
        s[i] = 0;
    hw_sprintf(s, "lalka: %0+u ololo", 42);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: %u ololo", 69);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: %+u ololo", 78);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: %+u ololo", -1);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: %+u %++u %0+++u ololo", -1, -2, -3);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: %0u %u ololo", 12, 54);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: %u=%+-u ololo", 12, 54);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: %u=%-u ololo", 12, 54);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: %-u=%u ololo", 12, 54);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: % u ololo", 12);
    printf("%s\n", s);
    hw_sprintf(s, "lalka: % 0u%% ololo", 12);
    printf("%s\n", s);
    return 0;
}
