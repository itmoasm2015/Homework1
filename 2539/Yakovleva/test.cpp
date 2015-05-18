#include "hw1.h"
#include <stdio.h>
#include <string>
#include <iostream>
#include <cstdlib>
#include <algorithm>

using namespace std;

char out[10000];

string itosu(unsigned long long x) {
	if (x == 0) return "0";
	string res = "";
	bool m = false;
	if (x < 0) {
		m = true;
		x = -x;
	}
	while (x != 0) {
		res += x % 10 + '0';
		x /= 10;
	}
	if (m) res += "-";
	reverse(res.begin(), res.end());
	return res;
}

string itos(long long x) {
	if (x == 0) return "0";
	string res = "";
	bool m = false;
	if (x < 0) {
		m = true;
		x = -x;
	}
	while (x != 0) {
		res += x % 10 + '0';
		x /= 10;
	}
	if (m) res += "-";
	reverse(res.begin(), res.end());
	return res;
}

bool testLL() {
	for (int i = -1000; i < 1000; i++) {
		long long a = (long long)i * 1000000000 + i;
		hw_sprintf(out, "!%llu!", a);
		string s = string(out);
//		unsigned long long b = (unsigned long long)a;
		string res = "!" + itosu(a) + "!";
		if (s != res) {
			printf("FAIL expected %s, got %s\n", res.c_str(), s.c_str());
			return false;
		} else {
			printf("OK answer = %s\n", s.c_str());
		}
	}
	return true;
}

bool testInt() {
	for (int i = -10000; i < 10000; i++) {
		hw_sprintf(out, "!%d!", i);
		string s = string(out);
		string res = "!" + itos(i) + "!";
		if (s != res) {
			printf("FAIL expected %s, got %s\n", res.c_str(), s.c_str());
			return false;
		} else {
			printf("OK answer = %s\n", s.c_str());
		}
	}
	return true;
}

char tmp[10000];
string fl = "+ -0";
string type = "udi%";
bool tp(int a, int b, int c, int d, int num) {
//	int num = 12345;
	string s = "%";
	for (int i = 0; i < 4; i++) {
		if (a & (1 << i)) s += fl[i];
	}
	s += itos(b);
	if (c == 1) s += "ll";
	for (int i = 0; i < 4; i++) {
		if (d == i) s += type[i];
	}
	hw_sprintf(out, s.c_str(), num);
	sprintf(tmp, s.c_str(), num);
	if (string(out) != string(tmp)) {
		printf("FAIL expected !%s!, got !%s!, req = !%s!\n", tmp, out, s.c_str());
		return false;
	} else {
		printf("OK answer = !%s!\n", out);
	}
	return true;
}
string dd[4];
bool itp(int a, int b, int c, int d, int num) {
//	int num = 12345;
	dd[0] = "";
	dd[1] = "";
	dd[2] = "";
	dd[3] = "";
	string s = "%";
	for (int i = 0; i < 4; i++) {
		if (a & (1 << i)) dd[0] += fl[i];
	}
	dd[1] += itos(b);
	//if (c == 1) dd[2] += "ll";
	for (int i = 0; i < 4; i++) {
		if (d == i) dd[3] += type[i];
	}
	random_shuffle(dd, dd + 4);
	s += dd[0] + dd[1] + dd[2] + dd[3] + "%d";
	hw_sprintf(out, s.c_str(), num);
	sprintf(tmp, s.c_str(), num);
	if (string(out) != string(tmp)) {
		printf("FAIL expected !%s!, got !%s!, req = !%s!\n", tmp, out, s.c_str());
		return false;
	} else {
		printf("OK answer = !%s!\n", out);
	}
	return true;
}
bool testParam() {
	//+ -0
	//width
	//ll
	//udi%
	for (int i = -10; i < 10; i++) {
		for (int j = 0; j < 16; j++) {
			for (int k = 1; k < 100; k++) {
				for (int h = 0; h < 2; h++) {
					for (int l = 0; l < 4; l++) {
	//					if (!tp(j, k, h, l, i)) return false;
						if (!itp(j, k, h, l, i)) return false;
					}
				}
			}
		}

	}
	return true;
}

int main() {
    printf("START TEST\n");
//	if (testInt()) {
//		if (testLL()) {
			testParam();
//		}
//	}
//    hw_sprintf(out, "Hello world !%7d!% 10d!\n", 12567, -4234853);
//    printf("RESULT=!%s!\n", out);
//    hw_sprintf(out, "Hello world !%lld!% 10d!\n", -42949672976, -4234853);
//    printf("RESULT=!%s!\n", out);
//    hw_sprintf(out, "Hello world !%lld!% 10d!", 10000000000000, -4234853);
//    printf("RESULT=!%s!\n", out);
//    hw_sprintf(out, "Hello world !%lld!% 10d!", -100000000000000, -4234853);
//    printf("RESULT=!%s!\n", out);
//    hw_sprintf(out, "Hello world %d", 239);
//    printf("RESULT=!%s!\n", out);
//    "Hello world 239"
//    hw_sprintf(out, "%+5u", 51);
//    printf("RESULT=!%s!\n", out);
//    "  +51"
//Test failed: "%lld" -> expected "1152921504606846975", got "+1152921500311879681"
    hw_sprintf(out, "% l%d", 123);
    printf("RESULT=!%s!\n", out);

    hw_sprintf(out, "%-08d", 123);
    printf("RESULT=!%s!\n", out);

    hw_sprintf(out, "%lld", -1152921504606846975);
    printf("RESULT=!%s!\n", out);

    hw_sprintf(out, "%-8u", 1234, 1234);
    printf("RESULT=!%s!\n", out);
//    "    1234=1234    "
    hw_sprintf(out, "%llu", (long long)-1);
    printf("RESULT=!%s!\n", out);
//    "18446744073709551615"
    hw_sprintf(out, "%wtf", 1, 2, 3, 4);
    printf("RESULT=!%s!\n", out);
//    "%wtf"
    hw_sprintf(out, "50%%");
    printf("RESULT=!%s!\n", out);
//    "50%"
    hw_sprintf(out, "%+++ll%", 12);
    printf("RESULT=!??%s!\n", out);
//    hw_sprintf(out, "%1000000i", 12);
//    printf("RESULT=!%s!\n", out);
    hw_sprintf(out, "%+10-0000d", 123);
    printf("RESULT=!%s!\n", out);
    return 0;
}

