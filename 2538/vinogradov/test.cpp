#include <sys/types.h>
#include <unistd.h>
#include <iostream>
#include <cassert>
#include <cstdio>
#include <string.h>

extern "C" void hw_sprintf(char *out, char const *format, ...);

void sample_printf(char const *format, int n) {
  char out[1024]; // supposed to be enough
  sprintf(out, format, n);
  std::cout << out;
  std::cout << "\n*************\n";
}

void hw_printf(char const *format, int n) {
  char out[1024]; // supposed to be enough
  char out2[1024];
  sprintf(out2, format, n);
  hw_sprintf(out, format, n);
  if (strcmp(out, out2) != 0) {
    std::cout << "bad " << format << "\n";
    std::cout << "> " << out << "<\n";
    std::cout << "> " << out2 << "<\n";
  } else {
    std::cout << "OK " << out << "\n";
  }
}

int main() {
  printf(">>>>>>>>>> start\n");
  hw_printf("|%++++10i|", -5189321);
  hw_printf("|%+++010i|", -5189321);
  hw_printf("|%++ +10i|", -5189321);
  hw_printf("|%++ 010i|", -5189321);
  hw_printf("|%+-++10i|", -5189321);
  hw_printf("|%+-+010i|", -5189321);
  hw_printf("|%+- +10i|", -5189321);
  hw_printf("|%+- 010i|", -5189321);
  hw_printf("|%   010i|", -5189321);
  hw_printf("|%    10i|", -5189321);
  hw_printf("|%  -010i|", -5189321);
  hw_printf("|%  - 10i|", -5189321);
  hw_printf("|%-010i|"  , -5189321);
  hw_printf("|%-10i|"   , -5189321);
  hw_printf("|%010i|"   , -5189321);
  hw_printf("|%10i|"    , -5189321);
  return 0;
}
