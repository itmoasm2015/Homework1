#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>

// STATE variable
//   5     4     1     0
// [ _ ] [ _ _ _ _ ] [ _ ]
// |     |           |___  control flag
// |     |_______________  flags
// |_____________________  size

const int CONTROL_FLAG_STATE = 1 << 0;
const int FLAG_PLUS_STATE = 1 << 1;
const int FLAG_SPACE_STATE = 1 << 2;
const int FLAG_MINUS_STATE = 1 << 3;
const int FLAG_ZERO_STATE = 1 << 4;
const int SIZE_LONG_STATE = 1 << 5;

#define print_num(T)     T num = va_arg(vl, T); \
                         T temp = num; \
                         int len = 0; \
                         do { \
                             temp /= 10; \
                             --width; \
                             ++len; \
                         } while (temp != 0); \
                         if (num < 0 || state & FLAG_PLUS_STATE || state & FLAG_SPACE_STATE) { \
                             width--; \
                         } \
                         if (!(state & FLAG_MINUS_STATE)) { \
                             for (int i = 0; i < width; i++) { \
                                 *out++ = state & FLAG_ZERO_STATE ? '0' : ' '; \
                             } \
                         } \
                         if (num < 0) { \
                             *out++ = '-'; \
                         } else if (state & FLAG_PLUS_STATE) {\
                             *out++ = '+'; \
                         } else if (state & FLAG_SPACE_STATE) {\
                             *out++ = ' '; \
                         } \
                         out += len; \
                         do { \
                             out--; \
                             *out = (char) ('0' + num % 10); \
                             num /= 10; \
                         } while (num != 0); \
                         out += len; \
                         if (state & FLAG_MINUS_STATE) { \
                             for (int i = 0; i < width; i++) { \
                                 *out++ = ' '; \
                             } \
                         } \
                         state = width = 0;

int hw_atoi(const char * in, int * out) {
    int len = 0;
    const char * in_orig = in;

    do {
        ++in;
        ++len;
    } while ('0' <= *in && *in <= '9');

    *out = 0;
    do {
        --in;
        *out *= 10;
        *out += *in - '0';
    } while (in_orig != in);

    return len;
}

void hw_sprintf(char * out, const char * format, ...) {
    int state = 0;
    int width = 0;
    va_list vl;

    va_start(vl, format);

    do {
        // read new character from format
        char cur = *format;
        if (cur == '%') {
            // if control flag was set, reset it
            // and vice versa
            state ^= CONTROL_FLAG_STATE;
        }

        if (state & CONTROL_FLAG_STATE) {
            // process flags
            if (cur == '+') state |= FLAG_PLUS_STATE;
            else if (cur == ' ') state |= FLAG_SPACE_STATE;
            else if (cur == '-') state |= FLAG_MINUS_STATE;
            else if (cur == '0') state |= FLAG_ZERO_STATE;

            // process width
            else if ('1' <= cur && cur <= '9') {
                format += hw_atoi(format, &width) - 1;
            }

            // process size
            else if (cur == 'l' && *(format + 1) == 'l') {
                state |= SIZE_LONG_STATE;
                ++format;
            }

            // process type
            else if (cur == 'i' || cur == 'd') {
                // int64 output
                if (state & SIZE_LONG_STATE) {
                    print_num(int64_t);
                }
                // int32 output
                else {
                    print_num(int32_t);
                }
            }

            else if (cur == 'u') {
                // uint64 output
                if (state & SIZE_LONG_STATE) {
                    print_num(uint64_t);
                }
                // uint32 output
                else {
                    print_num(uint32_t);
                }
            }

            // preverse malformed control seqs
            else if (cur != '%') {
                *out++ = '%';
                *out++ = cur;
                state = width = 0;
            }
        } else {
            // output non-control characters as-is
            *out++ = cur;
        }
    } while (*format++ != '\0');

    *out = '\0';
    va_end(vl);
}

int main() {
    char out[256];

    // some tests
    hw_sprintf(out, "Hello world %d\n", 239);
    printf("%s", out);
    hw_sprintf(out, "%+5u\n", 51);
    printf("%s", out);
    hw_sprintf(out, "%8u=%-8u\n", 1234, 1234);
    printf("%s", out);
    hw_sprintf(out, "%llu\n", (long long)-1);
    printf("%s", out);
    hw_sprintf(out, "%wtf\n", 1, 2, 3, 4);
    printf("%s", out);
    hw_sprintf(out, "50%%\n");
    printf("%s", out);

    return 0;
}
