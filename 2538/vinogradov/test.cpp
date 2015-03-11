#include <sys/types.h>
#include <unistd.h>
#include <iostream>
#include <cassert>
#include <cstdio>
#include <string.h>
#include <climits>

extern "C" void hw_sprintf(char *out, char const *format, ...);

std::string format(int flags) {
  std::string flags1, flags_u;
  assert(0 <= flags && flags <= 0b1111);
  if (flags & 0b0001) flags1 += "+";
  if (flags & 0b0010) flags1 += " ";
  if (flags & 0b0100) flags_u += "-";
  if (flags & 0b1000) flags_u += "0";

  std::string flags_s = flags1 + flags_u;

  std::string s = "$";
  std::string format_str =
    "^%"   + flags_s + "12d" +
    " | %" + flags_u + "12u" +
    " | %" + flags_s + "25lld" +
    " | %" + flags_u + "25llu" +
    "$";

  return format_str;
}

void hw_printf(char const *format, int a, unsigned b, long long c, long long unsigned d, const char* expected = nullptr) {
  const int BUF_SIZE = 1024; // supposed to be enough
  char out[BUF_SIZE];
  for (size_t i=0; i<BUF_SIZE; i++) {
    out[i] = '#';
  }
  hw_sprintf(out, format, a, b, c, d);
  char out_printf[BUF_SIZE];
  const char *out2;
  if (expected) {
    out2 = expected;
  } else {
      sprintf(out_printf, format, a, b, c, d);
      out2 = out_printf;
  }
  if (strcmp(out, out2) != 0) {
    std::cout << "bad " << format << "\n";
    std::cout << "> " << out << "<\n";
    std::cout << "> " << out2 << "<\n";
  }
}

int main() {
  std::cout << ">>>>>>>>>> start\n";
  for (int f=0; f<0b1111; f++) {
    char const *fmt = format(f).c_str();
    hw_printf(fmt, 0, 0, 0, 0);
    hw_printf(fmt, 1, 1, 1, 1);
    hw_printf(fmt, -1, -1, -1, -1);
    hw_printf(fmt, INT_MAX, INT_MAX, LLONG_MAX, LLONG_MAX);
    hw_printf(fmt, INT_MIN, INT_MIN, LLONG_MIN, LLONG_MIN);
  }
  hw_printf("^%+--ll% %0+0-llwt", 1,2,3,4, "^% %0+0-llwt");
  std::cout << "<<<<<<<<<< end\n";
  return 0;
}
