#include "include/hw1.h"
#include "include/my_sprintf.h"
#include <iostream>
#include <ctime>
#include <cstdlib>

using namespace std; 

namespace {
    const int MAX_RES = 100000;
    unsigned const number_of_iterations = 100;

    template<typename ...Types>
    bool check(string format, Types...args) {
        char my_ans[MAX_RES];
        char correct_ans[MAX_RES];
        my_sprintf(correct_ans, format.c_str(), args...); 
        hw_sprintf(my_ans, format.c_str(), args...); 
        if  (string(my_ans) != string(correct_ans)) {
            cerr << "expected: " << correct_ans << endl;
            cerr << "passed:   " << my_ans << endl;
            return false;
        }
        return true;
    }

    unsigned long long my_rand() {
        if (rand() & 1)
            return -(((unsigned long long) rand()) * rand() * rand());
        return (((unsigned long long) rand()) * rand() * rand());
    }

    void check(string format) {
        for (size_t i = 0; i < number_of_iterations; i++) {
            unsigned long long value1 = my_rand();
            unsigned long long value2 = my_rand();
            unsigned long long value3 = my_rand();
            if (!(check(format, value1, value2, value3))) {
                cerr << "format: " + format << endl;
                cerr << "unsigned long long" << endl;
                cerr << value1 << endl << value2 << endl << value3;
                exit(0);
            }

            if (!(check(format, (long long) value1, (long long) value2, (long long) value3))) {
                cerr << "format: " + format << endl;
                cerr << "long long" << endl;
                cerr << (long long) value1 <<  (long long) value2 <<  (long long) value3;
                exit(0);
            }

            if (!(check(format, (int) value1, (int) value2, (int) value3))) {
                cerr << "format: " + format << endl;
                cerr << "int" << endl;
                cerr << (int) value1 << endl << (int) value2 << endl << (int) value3;
                exit(0);
            }

            if (!(check(format, (unsigned int) value1, (unsigned int) value2, (unsigned int) value3))) {
                cerr << "format: " + format << endl;
                cerr << "unsigned int" << endl;
                cerr << (unsigned int) value1 << endl << (unsigned int) value2 << endl << (unsigned int) value3;
                exit(0);
            }

            if (!(check(format, value1, (long long) value2, (unsigned int) value3, (int) value1))) {
                cerr << "format: " + format << endl;
                cerr << "unsigned long long" << endl;
                cerr << "long long" << endl;
                cerr << "unsigned int" << endl;
                cerr << "int" << endl;
                cerr << value1 << endl << (long long) value2 << endl << (unsigned int) value3 << endl << (int) value1;
                exit(0);
            }

        }
    }
}

int main() {
    srand(time(NULL));
    check("|%+05u|");
    check("|% u|");
    check("|%+5u|");
    check("|%wtf|");
    check("|Hello world %d|");
    check("|%8u=%-8u|");
    check("|%100d|");
    check("|%+10-0000d|");
    check("|% l%d|");
    check("|%ll %d|");
    check("hello, friend %+- 109llo, %0+-  %, %d");
    check("|%d| {% 08u=%+08u}{%+04d=%+0-6d}");
    check("|%lld|");
    cerr << "GOOD!" << endl;
}



