#include <string>
#include <iostream>
#include <cstdio>
#include "homework1.h"

using namespace std;

int main() {
    char container[1024];
    long long int param = 1111222233334444;
    long long int minusone = -1;

    hw_sprintf(container, "M%-18lldmda))% +010da", param, 228);
    cout << container << endl;
    sprintf(container, "M%-18lldmda))% +010da", param, 228);
    cout << container << endl;

    hw_sprintf(container, "0x<% 013u>", 228);
    cout << container << endl;
    sprintf(container, "0x<% 013u>", 228);
    cout << container << endl;

    hw_sprintf(container, "%8u=%-8u", 1234, 1234);
    cout << container << endl;
    sprintf(container, "%8u=%-8u", 1234, 1234);
    cout << container << endl;

    hw_sprintf(container, "%+5d", 1);
    cout << container << endl;
    sprintf(container, "%+5d", 1);
    cout << container << endl;

    return 0;
}
