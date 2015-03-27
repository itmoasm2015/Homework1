#include <string>
#include <iostream>
#include <cstdio>
#include "homework1.h"

using namespace std;

int main() {
    char container[1024];
    long long int param = 1111222233334444;
    long long int minusone = -1;
    hw_sprintf(container, "M%+31lldmd%+--+--+--lol))))% +da", param, 228);
    cout << container << endl;
    sprintf(container, "Mem%d", 1234);
    cout << container << endl;
    return 0;
}
