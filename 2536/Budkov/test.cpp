#include "hw1.h"
#include <stdio.h>
#include <string.h>
#include <string>
#include <stdarg.h>

using namespace std;

const int SIZE = 4096;
char resbuf[SIZE];
char buf[SIZE];
int check = 1;

void test(string test) 
{
    if (strcmp(buf, resbuf)) 
    {
        printf("Failed\n");
        printf("%s\n", test.c_str());
	check = 0;
    }
    else 
    {
        printf("OK\n");
    }
}

void run2(const string format, int a1, int a2) 
{
    const char* tmp = format.c_str();
    hw_sprintf(resbuf, tmp, a1, a2);
    sprintf(buf, tmp, a1, a2);
    test(format);
}

void run1(const string format, int a1) 
{
    const char* tmp = format.c_str();
    hw_sprintf(resbuf, tmp, a1);
    sprintf(buf, tmp, a1);
    test(format);
}

int main(int argc, char *argv[]) 
{
    run2("%2d %03d", -1, -1);
    run2("%2d % 04d", -1, -1);
    run2("% 4d % 4d", -1, 1);
    run1("%llu", (long long) -1);
    run1("%llu", (long long) 2 << 33 - 1);
    run1("%d", 2147483647);
    run1("%u", -1);
    run1("%01u", -1);
    run1("%%d", 0);
    run2("% d % d", 100, -100);
    run2("% d %+d", 100, 100);
    run2("%10d %010u", 0, 111);
    run2("10d %-10u", 0, 111);
    run2("%2d %3d", -1, -1);
    run1("%-%%d", 123);
    run2("%-00-%%d % -010% %-0 10lli", 123, (long long) 321);
    run2("10lli %-10lli", (long long)0, (long long)111);   
    if(check==1)
    {
	printf("All tests passed!");
    }
}
