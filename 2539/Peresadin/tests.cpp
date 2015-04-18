#include <bits/stdc++.h>
#include "hw1.h"
#define format1 "%0+10u | %0-+10u"

std::string gen_flag(int len) {
	std::string format = "%";
	for (int i = 0; i < 7; ++i) {
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
	format += "d";
	//format += '\n';
	return format;
}

void let_first_stage_test() 
{
	int n = 1;
	int arg[n];
	char my_out[10000];
	char true_out[10000];
	memset(my_out, 0, 10000);
	memset(true_out, 0, 10000);
	std::string format = "";
	for (int i = 0; i < n; ++i) 
		format += gen_flag(rand() % 7);
	for (int i = 0; i < n; ++i)
		arg[i] = rand() % 12345;
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
  int num = 1;

hw_sprintf(out, "50%%");
  printf("%s\n", out);
  //std::string fm = "% +0-01d% -+0-6d%+ - 06d#";
  //std::string fm = "% +0-01d% -+0-6d%+ - 064d%00++-7d%-0 ++6d%0- ++66d%0--006d%-0- -83d%+-0- 7d%   +04d";
  //std::string fm1 = " %-0 0 5d%-+0 069d%0 00 7d%- +- 9d% 0  +3d% -+- 7d%+0-0+5d%+0-007d%    08d% +---9d";
  //hw_sprintf(     out, fm.c_str(), num, num, num, num, num, num, num, num);
  //hw_sprintf(true_out, fm.c_str(), num, num, num, num, num, num, num, num);
  //printf("%s\n=======\n%s\n", out, true_out);
  //std::cerr << strcmp(out, true_out) << "\n";
  for (int i = 0; i < 10000; ++i) {
  	let_first_stage_test();}

  //hw_sprintf(out, format1, -12345, 12345);
  //std::cerr << out << "\n";
  //sprintf(true_out, format1, -12345, 12345);
  //std::cerr << true_out << "\n";
  //std::cout << strcmp(out, true_out) << std::endl;
  //std::cerr << "OK. All test passed" << "\n";
	return 0;
}
