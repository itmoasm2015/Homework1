//#include <hw1.h>
#include "hw_1.h"
#include <bits/stdc++.h>

using namespace std;
const int N = 1e6 + 1;

char s[N];

void superTest() {
    char buf[1024];

    hw_sprintf(buf, "Hello World %d", 239);
    assert(strcmp(buf, "Hello World 239") == 0);

    hw_sprintf(buf, "%+5u", 51);
    assert(strcmp(buf, "  +51") == 0);

    hw_sprintf(buf, "%8u=%-8u", 1234, 1234);
    assert(strcmp(buf, "    1234=1234    ") == 0);

    hw_sprintf(buf, "%llu", (long long)-1);
    assert(strcmp(buf, "18446744073709551615") == 0);

    hw_sprintf(buf, "%+10-0000d", 123);
    assert(strcmp(buf, "%+10-0000d") == 0);

    hw_sprintf(buf, "% l%d", 123);
    assert(strcmp(buf, "% l123") == 0);

    hw_sprintf(buf, "%wtf", 1, 2, 3, 4);
    assert(strcmp(buf, "%wtf") == 0);

    hw_sprintf(buf, "50%%");    
    assert(strcmp(buf, "50%") == 0);

    hw_sprintf(buf, "%wtf 50%% %+5u", 51);
    assert(strcmp(buf, "%wtf 50%   +51") == 0);

    hw_sprintf(buf, "%ll %d", 123);
    assert(strcmp(buf, "%ll 123") == 0);

    hw_sprintf(buf, "%-%%d", 123);
    assert(strcmp(buf, "%123") == 0);

    hw_sprintf(buf, "%lld", -17LL);
    assert(strcmp(buf, "-17") == 0);

    printf("OK\n");


}

int main() {
    superTest();
    //freopen("out.txt", "w", stdout);
    //void *t = s;
    //cerr << t << endl;
    //cerr << "pointer s: " << (void *)s << endl;
    //supperTest();
    //hw_sprintf(s, "\"%8u=%-8u\"", 1234, 1234);
    //hw_sprintf(s, "\"%llu\"", -1ll);
    hw_sprintf(s, "%+010d", 1);
    hw_sprintf(s, "%+010d", -1);
    //hw_sprintf(s, "Hello world %d", 6463497770442498592ull);
    cout << s << endl;
    //f(s1, s2);
    //cerr << "s1:" << s1 << endl;
    //cerr << "s2:" << s2 << endl;


    return 0;
}
