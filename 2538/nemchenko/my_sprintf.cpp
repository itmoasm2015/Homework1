#include "include/hw1.h"
#include <iostream>
#include <cstdarg>
#include <cstdlib>

using namespace std;

int field_width;
int len_str_repr;
char flags;
char cur_char;
char str_repr[22];
const char* format;
const char plus_flag = 0x1;
const char minus_flag = 0x2;
const char space_padding_flag = 0x4;
const char zero_padding_flag = 0x10;
const char size8_flag = 0x20;
const char negative_flag = 0x40;

bool is_digit(char x) {
    return (x - '0' >= 0 && x - '0' < 10);
}

void reverse(char* out, char* end) {
    while (out < end) {
        char tmp = *out;
        *out = *end;
        *end = tmp;
        out++;
        end--;
    }
}


int num_to_str(unsigned long long value, char* result) {
    int len = 0;
    do {
        *result = (char) (value % 10 + '0');
        value /= 10;
        result++;
        len++;
    } while (value);

    return len;
}

void set_flags() {
    while (true) {
        if (cur_char == '+') {
            flags |= plus_flag;
        } else if (cur_char == '-') {
            flags |= minus_flag;
        } else if (cur_char == '0') {
            flags |= zero_padding_flag;
        } else if (cur_char == ' ') {
            flags |= space_padding_flag;
        } else {
            break;
        }
        cur_char = *(format++);
    }
}

void parse_field_width() {
    // parse field_width
    while (is_digit(cur_char)) {
        field_width = field_width * 10 + (cur_char - '0');
        cur_char = *(format++);
    }
}

void print_sign(char*& out) {
    if (flags & negative_flag) {
        *out = '-';
    } else if (flags & plus_flag) {
        *out = '+';
    } else if (flags & space_padding_flag) {
        *out = ' ';
    } else {
        return;
    }
    out++;
}

void print_number(char*& out) {
    while (len_str_repr > 0) {
        len_str_repr--;
        *out = str_repr[len_str_repr]; 
        out++;
    }
}

void my_sprintf(char *out, char const *format2, ...) {
    format = format2;
    va_list vl;
    va_start(vl, format2);
    while (true) {
        *out = 0;
        if (*format == 0) break;

        char const* begin_format = format;
        cur_char = *(format++);

        if (cur_char != '%') {
            *out = cur_char;
            out++;
            continue;
        }
        cur_char = *(format++);

        flags = 0;
        field_width = 0;

        set_flags();
        parse_field_width();

        if (cur_char == '%') {
            *out = '%';
            out++;
            continue;
        }

        unsigned long long value;
        // parse size
        if (cur_char == 'l' && *format == 'l') {
            flags |= size8_flag;
            format++;
            cur_char = *(format++);
        }

        // parse type
        if (cur_char == 'u') { 
            if (flags & size8_flag) {
                value = va_arg(vl, unsigned long long);
            } else {
                value = va_arg(vl, unsigned int);
            }
        } else if (cur_char == 'd' || cur_char == 'i') { // signed 
            if (flags & size8_flag) {
                value = va_arg(vl, long long);
                if ((long long) value < 0) {
                    flags |= negative_flag;
                    value = ~value + 1;
                }
            } else {
                value = va_arg(vl, int);
                if ((int) value < 0) {
                    flags |= negative_flag;
                    value = (~value + 1) & 0xffffffff;
                }
            }
        } else { 
            while (begin_format != format) {
                *out = *begin_format;
                begin_format++;
                out++;
            }
            continue;
        } // print_incorrect_format

        len_str_repr = num_to_str(value, str_repr);

        int padding_size = field_width - len_str_repr;
        if (flags & (plus_flag | space_padding_flag | negative_flag)) {
            padding_size--;
        }

        if (padding_size > 0) {
            if (flags & minus_flag) {
                print_sign(out);
                print_number(out);
                while (padding_size) {
                    *out = ' ';
                    out++;
                    padding_size--;
                }
            } else {
                if (flags & zero_padding_flag) {
                    print_sign(out);
                    while (padding_size) {
                        *out = '0';
                        out++;
                        padding_size--;
                    }
                } else {
                    while (padding_size) {
                        *out = ' ';
                        out++;
                        padding_size--;
                    }
                    print_sign(out);
                }
                print_number(out);
            }
        } else {
            print_sign(out);
            print_number(out);
        }
    }

    va_end(vl);
}

//int main() {
    //char out[1000];
    //my_sprintf(out, "|%d| {% 08u=%+08u}{%+04d=%+0-6d}", 10, 1234, 1234, 1, -1);
    //cerr << out  << endl;

    //return 0;
//}
