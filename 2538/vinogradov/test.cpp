#include <sys/types.h>
#include <unistd.h>
#include <iostream>
#include <cassert>
#include <cstdio>
#include <string.h>

extern "C" void hw_sprintf(char *out, char const *format, ...);

void hw_printf(char const *format, long long a, int b) {
  char out[1024]; // supposed to be enough
  char out2[1024];
  hw_sprintf(out, format, a, b);
  sprintf(out2, format, a, b);
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
  hw_printf("|%++++10lld %i|", -3123456789, 1);
  hw_printf("|%+++010lld %i|", -3123456789, 1);
  hw_printf("|%++ +10lld %i|", -3123456789, 1);
  hw_printf("|%++ 010lld %i|", -3123456789, 1);
  hw_printf("|%+-++10lld %i|", -3123456789, 1);
  hw_printf("|%+-+010lld %i|", -3123456789, 1);
  hw_printf("|%+- +10lld %i|", -3123456789, 1);
  hw_printf("|%+- 010lld %i|", -3123456789, 1);
  hw_printf("|%   010lld %i|", -3123456789, 1);
  hw_printf("|%    10lld %i|", -3123456789, 1);
  hw_printf("|%  -010lld %i|", -3123456789, 1);
  hw_printf("|%  - 10lld %i|", -3123456789, 1);
  hw_printf("|%-010lld %i|"  , -3123456789, 1);
  hw_printf("|%-10lld %i|"   , -3123456789, 1);
  hw_printf("|%010lld %i|"   , -3123456789, 1);
  hw_printf("|%10lld %i|"    , -3123456789, 1);
  return 0;
}
