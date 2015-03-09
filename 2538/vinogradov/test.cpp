#include <sys/types.h>
#include <unistd.h>
#include <iostream>
#include <cassert>
#include <cstdio>

extern "C" void hw_sprintf(char *out, char const *format, ...);

void sample_printf(char const *format, int n) {
  char out[1024]; // supposed to be enough
  sprintf(out, format, n);
  std::cout << out;
  std::cout << "\n*************\n";
}

void hw_printf(char const *format, int n) {
  char out[1024]; // supposed to be enough
  hw_sprintf(out, format, n);
  std::cout << out;
  std::cout << "&&&\n";
  printf(format, n);
  std::cout << "\n*************\n";
}

int main() {
  //hw_printf("AbcdEfgh%123", 9);
  hw_printf("|%+ -10i|", 13124);
  return 0;
}
