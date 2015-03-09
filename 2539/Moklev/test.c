#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

void hw_sprintf(char *out, char const *format, ...);

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

int idata[] = {0, 1, -1, 123, -123, 0x80000000, 0x7fffffff, 987654321, -987654321, 12312344};
unsigned uidata[] = {0, 1, 123, 123456789, 987654321, 0xffffffff, 0x80000000, 0x7fffffff, 1, 1};
long long lldata[] = {0, 1, -1, 123456789, 987654321, 0x80000000, 0xffffffff, 0x7fffffffffffffff, 0x8000000000000000, 0x7fffffffff};
unsigned long long ulldata[] = {0, 1, 123456789, 987654321, 0x7fffffff, 0xff00000000, 0xffffffffffffffff, 0x8000000000000000, 0x7fffffffffffffff, 0x123412341234};

int compare(const char * a, const char * b)
{
    int i = 0;
    while (a[i] != 0) {
        if (a[i] != b[i])
            return 0;
        i++;
    }
    return 1;
}

int verbose = 0;
int count_test = 0;
int passed = 0;

int test(const char* s, unsigned long long aa, unsigned long long bb, unsigned long long cc)
{
    char a[1000], b[1000];
    count_test++;

    hw_sprintf(a, s, aa, bb, cc);
    sprintf(b, s, aa, bb, cc);
    if (compare(a, b) == 0) {
        //if (verbose) 
            printf("Test failed:\n%s\n%s\n", b, a);
        //else 
        //    printf("FAILED\n");
    } else {
        passed++;
        //if (verbose)
        //    printf("Test OK:     \n%s\n\n", a);
        //else
        //    printf("OK\n");
    }
}

int expect(const char* ex, const char * s, unsigned long long aa, unsigned long long bb, unsigned long long cc) 
{
    char a[1000];
    count_test++;
    
    hw_sprintf(a, s, aa, bb, cc);
    if (compare(a, ex) == 0) {
        //if (verbose) 
            printf("Test failed:\n%s\n%s\n", ex, a);
        //else 
        //    printf("FAILED\n");
    } else {
        passed++;
        //if (verbose)
        //    printf("Test OK:     \n%s\n\n", a);
        //else
        //    printf("OK\n");
    }
}


int main() {

    
    int time1;            
    int a = 0, b = 0;    
    
        expect("lalka: %0+24-llu ololo", "lalka: %0+24-llu ololo", 42, 0, 0);
    test("lalka: %0+24u ololo", 42, 0, 0);
    test("lalka: %0% ololo", 42, 0, 0);
    test("lalka: %u ololo", 69, 0, 0);
    test("lalka: %+u ololo", 78, 0, 0);
    test("lalka: %+u ololo", -1, 0, 0);
    test("lalka: %+u %++u %0+++u ololo", -1, -2, -3);
    test("lalka: %0u %u ololo", 12, 54, 0);
    test("lalka: %u=%+-u ololo", 12, 54, 0);
    test("lalka: %u=%-u ololo", 12, 54, 0);
    test("lalka: %-u=%u ololo", 12, 54, 0);
    test("lalka: % u ololo", 12, 0, 0);
    test("lalka: % 0u%% ololo", 12, 0, 0);
    test("lalka: %d ololo", -42, 0, 0);
    test("lalka: %d ololo", 0x80000000, 0, 0);
    test("lalka: %+d ololo", -42, 0, 0);    
    test("lalka: %0+24d ololo", 42, 0, 0);
    test("lalka: %0% ololo", 42, 0, 0);
    test("lalka: %d ololo", 69, 0, 0);
    test("lalka: %+d ololo", 78, 0, 0);
    test("lalka: %+d ololo", -1, 0, 0);
    test("lalka: %+d %++d %0+++d ololo", -1, -2, -3);
    test("lalka: %0d %d ololo", -12, -54, 0);
    test("lalka: %d=%+-d ololo", -12, 54, 0);
    test("lalka: %d=%-d ololo", -12, -54, 0);
    test("lalka: %-d=%d ololo", -12, -54, 0);
    test("lalka: % d ololo", -12, 0, 0);
    test("lalka: % 0d%% ololo", -12, 0, 0);
    test("lalka: %20d%% ololo", -12, 0, 0);
    test("lalka: % 0llu ololo", -1, 0, 0);
    test("lalka: %lld ololo", -1, 0, 0);
    test("lalka: % 0llu ololo", 11123456789123456789ULL, 0, 0);
    test("lalka: % 0lld ololo", 11123456789123456789ULL, 0, 0);
    test("lalka:\n%u\n%d\n%llu\nololo", 11123456789123456789ULL, 11123456789123456789ULL, 11123456789123456789ULL);
    
    printf("%d / %d tests passed\n", passed, count_test);
    
    
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
    
    printf("%d / %d tests passed\n", a, b);
    time1 = clock();
        
    printf("time to wait\n");
    char dest_str[500];
    for(int i = 0; i < 5000000; i++) {
        hw_sprintf(dest_str, "%030lli %030lli %-30i %-30i", (long long) i, 0x0fffffffffffffffll, i, -i);
    }
    
    char* bs = (char*) malloc(1000000);
    hw_sprintf(bs, "%0999999i", 1);
    printf("time: %d\n", (clock() - time1) / (CLOCKS_PER_SEC / 1000));
    free(bs);
    
    return 0;
}