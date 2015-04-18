#include <stdio.h>
#include "hw_sprintf.h"



int main()
{
	char out[256];
	hw_sprintf(out, "|% 21d|", 1);
	printf("%s\n", out);
  hw_sprintf(out, "|%+-33u|", -1);
  printf("%s\n", out);
  hw_sprintf(out, "|%-0000000000001llu|", (long long) -1);
  printf("%s\n", out);
  hw_sprintf(out, "|%+++++++++- 50lld|", (long long) 123123123123);
  printf("%s\n", out);
  
	return 0;
}