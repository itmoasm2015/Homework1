#include "hw1.h"
#include <cstdio>

int main()
{
  char out[100] = "";
  hw_sprintf(out, "Hello world %d", 239);
  printf("%s\n", out);
  hw_sprintf(out, "%+5u", 51);
  printf("%s\n", out);
  hw_sprintf(out, "%8u=%-8u", 1234, 1234);
  printf("%s\n", out);
  hw_sprintf(out, "%llu", (long long) -1);
  printf("%s\n", out);
  hw_sprintf(out, "%wtf", 1, 2, 3, 4);
  printf("%s\n", out);
  hw_sprintf(out, "50%%");
  printf("%s\n", out);
  return 0;
}
