#include <string>
#include <iostream>
#include <cstdio>
#include "homework1.h"

using namespace std;

int main() {
    char container[1024];
    long long int param = 11111222222233333333;
    long long int minusone = -1;
    hw_sprintf(container, "M%+-0 353lld mdaa", -1);
    cout << container << endl;
    sprintf(container, "Mem%d", 1234);
    cout << container << endl;
    return 0;
}
