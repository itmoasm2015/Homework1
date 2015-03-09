#include "hw1.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define TEST(count, total, format, ...) { \
    char str[1000], str2[1000]; \
    sprintf(str, format, __VA_ARGS__); \
    hw_sprintf(str2, format, __VA_ARGS__); \
    int rs = !strcmp(str, str2); \
    if(!rs) {\
        printf("Miserable fail with %s " format " \n", format, __VA_ARGS__); \
        printf("sprintfy makes      %s %s \n", format, str); \
        printf("Got instead         %s %s \n\n", format, str2); \
    } \
    count += rs; \
    total++; \
} 

int idata[] = {0, 1, -1, 123, -123, 0x80000000, 0x7fffffff, 987654321, -987654321};
unsigned uidata[] = {0, 1, 123, 123456789, 987654321, 0xffffffff, 0x80000000, 0x7fffffff, 1, 1};
long long lldata[] = {0, 1, -1, 123456789, 987654321, 0x80000000, 0xffffffff, 0x7fffffffffffffff, 0x8000000000000000, 0x7fffffffff};
unsigned long long ulldata[] = {0, 1, 123456789, 987654321, 0x7fffffff, 0xff00000000, 0xffffffffffffffff, 0x8000000000000000, 0x7fffffffffffffff};

int main() {
    //printf("%d\n", hw_strlen("abacaba"));
    /*
    char buf[1024];
    hw_itoa(-15, buf);
    printf("latex: '%s'\n", buf);
    hw_itoa(20, buf);
    printf("heh: '%s'\n", buf);
    hw_itoa(0, buf);
    printf("%s\n", buf);
    int res = hw_itoa(29384723, buf);
    printf("%d : %s\n", res, buf);
    res = hw_itoa(-2384722, buf);
    printf("%d : %s\n", res, buf);

    res = hw_luitoa(1, buf);
    printf("%d : %s\n", res, buf);
    */
    char buf[1024];
    int res = hw_luitoa(34857693450LL, buf);
    printf("%d : %s\n", res, buf);
    /*    
    int a = 0, b = 0;
    TEST(a, b, "lel", 0)
    TEST(a, b, "%%", 0)
    TEST(a, b, "%+- 0123124%", 0)
    TEST(a, b, "%%", 0)
    TEST(a, b, "%%%%%%", 0)
    TEST(a, b, "% % % % % %", 0)
    
    for(int i = 0; i < 10; i++) {
        TEST(a, b, "%i> %u %i %llu %lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
        TEST(a, b, "%i> %30u %+30i %30llu %+30lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
        TEST(a, b, "%i> %-30u %-30i %-30llu %-30lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
        TEST(a, b, "%i> %030u %030i %030llu %030lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
        TEST(a, b, "%i> %30u % 30i %30llu % 30lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
        TEST(a, b, "%i> %0-30u %0-30i %0-30llu %0-30lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
        TEST(a, b, "%i> %-30u % -30i %-30llu % -30lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
        TEST(a, b, "%i> %-30u % -+30i %-30llu % -+30lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
        TEST(a, b, "%i> %030u %+030i %030llu %+030lld", i, uidata[i], idata[i], ulldata[i], lldata[i]);
    }
    
    printf("got %d/%d tests good\n", a, b);
    
    printf("time to wait\n");
    char dest_str[500];
    for(int i = 0; i < 5000000; i++) {
        hw_sprintf(dest_str, "%030lli %030lli %-30i %-30i", (long long) i, 0x0fffffffffffffffll, i, -i);
    }
    
    char* bs = (char*) malloc(1000000);
    hw_sprintf(bs, "%0999999i", 1);
    printf("long len %d\n", strlen(bs));
    free(bs);
    */
    return 0;
}
