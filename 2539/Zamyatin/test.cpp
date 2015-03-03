#include <bits/stdc++.h>
#include "hw1.h"
#define format1 "%llu"

std::string noise() {
	int len = 10;
	std::string t = "";
	while (len-->0) {
		t += rand() % 20 + 'a';
	}
	return t;
}

std::string gen_flag() {
	std::string format = "%";
	if (rand() % 10 == 0)
		format = noise() + "%";
	for (int i = 0; i < 5; ++i) {
		int t = rand() % 4;
		if (t == 0)
			format += '+';
		if (t == 1)
			format += ' ';
		if (t == 2)
			format += '-';
		if (t == 3)
			format += '0';
	}
	int num = rand() % 100;
	do {
		format += num % 10 + '0';
		num /= 10;
	} while (num > 0);
	//int t = rand() % 2;
	//if (t == 0)
		format += "ll";
	int t = rand() % 2;
	if (t == 0)
		format += "i";
	else 
		format += "u";
	//format += '\n';
	return format;
}

long long long_rand() {
	return ((long long)rand()) * rand();
}

void let_first_stage_test() 
{
	int n = 10;
	long long arg[n];
	char my_out[10000];
	char true_out[10000];
	memset(my_out, 0, 10000);
	memset(true_out, 0, 10000);
	std::string format = "";
	for (int i = 0; i < n; ++i) 
		format += gen_flag();
	for (int i = 0; i < n; ++i)
		arg[i] = long_rand();
	hw_sprintf(my_out, format.c_str(), arg[0], arg[1], arg[2], arg[3], arg[4], arg[5], arg[6], arg[7], arg[8], arg[9]);
	sprintf(true_out, format.c_str(), arg[0], arg[1], arg[2], arg[3], arg[4], arg[5], arg[6], arg[7], arg[8], arg[9]);
	if (memcmp(true_out, my_out, 1000) != 0) {
		std::cerr << (("Fail on "+ format).c_str()) << "\n";
		std::cerr << "True string: " << "|" << true_out << "|" << "\n";
		std::cerr << "My string:   " << "|" << my_out << "|" << "\n";
		std::cerr << "Args: ";
		for (int i = 0; i < n; ++i)
			std::cerr << arg[i] << " ";
		std::cerr << "\n";
		assert(0);
	} else {
		//std::cerr << "Ok: " + format + "\n";
	}
}

int main()
{
	srand(time(NULL));
	char out[10000];
  char true_out[10000];
  memset(out, 0, 10000);
  memset(true_out, 0, 10000);
  
  hw_sprintf(out, "Hello world %d!\n", 239);
  printf("%s", out);
  hw_sprintf(out, "%0+5d\n", 51);
  printf("%s", out);
  hw_sprintf(out, "<%12i=%-12u>\n", -1, -1);
  printf("%s", out);
  hw_sprintf(out, "%llu\n", (long long)-2);
  printf("%s", out);
  hw_sprintf(out, "%lli\n", (long long)-1);
  printf("%s", out);
  hw_sprintf(out, "%wtf\n", 1, 2, 3, 4);
  printf("%s", out);
  hw_sprintf(out, "50%%\n");
  printf("%s", out);
  hw_sprintf(out, "%%%d\n", 123);
  printf("%s", out);
  hw_sprintf(out, "%-10%=\n");
  printf("%s", out);
  hw_sprintf(out, "%50-%=\n");
  printf("%s", out);
  hw_sprintf(out, "%+10-0000d\n", 123);
  printf("%s", out);
  hw_sprintf(out, "%10lld\n", (long long) 123);
  printf("%s", out);
  hw_sprintf(out, "%ll10d\n", (long long) 123);
  printf("%s", out);
  hw_sprintf(out, "%ll%d\n", (long long) 123);
  printf("%s", out);
  hw_sprintf(out, "%+-010d=\n", 123);
  printf("%s", out);
  
  for (int i = 0; i < 10000; ++i) {
  	let_first_stage_test();
  }
  //printf("%ll\n");
  //printf(fm.c_str(),4294967296);
  std::cerr << "Ok. All tests passed\n";
	return 0;
}

