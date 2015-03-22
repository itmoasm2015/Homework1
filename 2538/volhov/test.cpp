#include <string>
#include <iostream>
#include <cstdio>
#include "homework1.h"

using namespace std;

int main() {
    char container[1024];
   hw_sprintf(container, "M%++a%34d mdaa", 228);
    cout << container << endl;
    sprintf(container, "Mem%d", 228);
    cout << container << endl;
    return 0;
}
