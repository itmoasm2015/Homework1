//FAQ:
//
//What is it?
//It is tester for hw_sprintf.
//
//It is GOVNOCODE!!!
//Yes it is.
//
//differences between homework and sprintf:
//'%+u' sprintf prints without '+', but hw_sprints prints '+'. so there is no that test
//same thing with '% u'  

#include <stdio.h>
#include "hw1.h"

char out1[100000];
char out2[100000];
char* format, *out3;
int errors;
int passes;

int check() {
	for (int i = 0; ;i++) {
		if (out1[i] != out2[i]) {
			printf("WA:\n your:%s\nright:%s\n", out1, out2);
			errors++;
			return 1;
		}
		if (out1[i] == 0) {
			break;
		}
	}
	//printf("ok:%s\n", out1);
	passes++;
	return 0;
}

int check_out3() {
  for (int i = 0; ;i++) {
    if (out1[i] != out3[i]) {
      printf("WA:\n your:%s\nright:%s\n", out1, out3);
      errors++;
      return 1;
    }
    if (out1[i] == 0) {
      break;
    }
  }
  //printf("ok:%s\n", out1);
  passes++;
  return 0;
}

int main() {
    int a, b, c, d, e, f, g, h;
    
    format = "%i %i %i %d %u %i";
    a = 1, b = -2, c = 3, d = -4, e = 5, f = -6;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

    format = "%-i %+i %+--++i %- - i %+ + i %-+ -+  -+i ";
    a = 10, b = 200, c = 3000, d = 40000, e = 500000, f = 6000000;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

    format = "%-i %+i %+--++i %- - i %+ + i %-+ -+  -+i ";
    a = -10, b = -200, c = -3000, d = -40000, e = -500000, f = -6000000;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

    format = "%i% i";
    a = -2147483648, b = 2147483647;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

  format = "23456789%wtf";
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

	format = "%wtf 50%% %%%%%%%% %";
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

    format = "༼ つ ◕_◕ ༽つ   ╭∩╮（︶︿︶）╭∩╮    ლ(ಠ益ಠლ)    ¯\\_(ツ)_/¯   ( ͡° ͜ʖ ͡°) ";
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();        

    format = "Аганов Артур";
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

    format = "%u %-23u %54u";
    a = 4294967295, b = 2147483647, c = 234;
    hw_sprintf(out1, format, a, b, c, d);
       sprintf(out2, format, a, b, c, d);
    check();

    format = "% 23i % 23i %-123i %-123d %+123i %+123i";
    a = 13425, b = -22134, c = 3234523, d = -423453, e = 56436, f = -62341;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

	format = "%i %i %i %i";
    hw_sprintf(out1, format, 1 == 1, 1, (short)129, 'a');
       sprintf(out2, format, 1 == 1, 1, (short)129, 'a');
    check();

    format = "";
    hw_sprintf(out1, format, 1 == 1, 1, (short)129, 'a');
       sprintf(out2, format, 1 == 1, 1, (short)129, 'a');
    check();

    format = "%0i %05i %05i %05d % 05i % 05i";
    a = 11, b = 22, c = -33, d = -4, e = 5, f = -6;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

    format = "%+0i %+05i %+05i %+05d % +05i % +05i";
    a = 11, b = 22, c = -33, d = -40, e = 0, f = -60;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

     format = "%+- 0i %+- 0123i %+- 0123i %+- 0123i %+- 0123i %+- 0123i";
    a = 1, b = -1, c = -33, d = -400000, e = 0, f = -60;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();


    long long la, lb, lc, ld, le, lf, lg;

    format = "%lli %lli %lli %lld %lli %llu %lli";

    la = 1, lb = 20000000000000ll, lc = 9223372036854775807ll, ld = 0, le = -100000000000000ll, lf = 18446744073709551615ull, lg = -4294967296ll;
    hw_sprintf(out1, format, la, lb, lc, ld, le, lf, lg);
       sprintf(out2, format, la, lb, lc, ld, le, lf, lg);
    check();

	format = "%llu %llu %llu %llu %llu %llu %llu";

    la = 1, lb = 2384837475848345ll, lc = 1231231343244123213ll, ld = 2345264536234, le = 100000000000000ll, lf = 18446744073709551615ull, lg = 4294967296ll;
    hw_sprintf(out1, format, la, lb, lc, ld, le, lf, lg);
       sprintf(out2, format, la, lb, lc, ld, le, lf, lg);
    check();    


	format = "%lli %lli %lli %lli %lli %lli %lli";

    la = -1, lb = 0xffffffffffffffff, lc = -1231231343244123213ll, ld = -2345264536234, le = -100000000000000ll, lf = -1844674407370955161, lg = -4294967296ll;
    hw_sprintf(out1, format, la, lb, lc, ld, le, lf, lg);
       sprintf(out2, format, la, lb, lc, ld, le, lf, lg);
    check();


        format = "% 123lli %0123lli %-12lli %lld %lli %llu %lli";

    la = 1, lb = 20000000000000ll, lc = 9223372036854775807ll, ld = 0, le = -100000000000000ll, lf = 18446744073709551615ull, lg = -4294967296ll;
    hw_sprintf(out1, format, la, lb, lc, ld, le, lf, lg);
       sprintf(out2, format, la, lb, lc, ld, le, lf, lg);
    check();    



    format = "%+10-0000d";
    a = 1, b = -1, c = -33, d = -400000, e = 0, f = -60;
    hw_sprintf(out1, format, a, b, c, d, e, f);
       sprintf(out2, format, a, b, c, d, e, f);
    check();

    format = "%0%d";
    out3 = "%01";
    a = 1, b = -1, c = -33, d = -400000, e = 0, f = -60;
    hw_sprintf(out1, format, a, b, c, d, e, f);
    check_out3();        

    format = "% l%d";
    out3 = "% l1";
    a = 1, b = -1, c = -33, d = -400000, e = 0, f = -60;
    hw_sprintf(out1, format, a, b, c, d, e, f);
    check_out3();

    format = "%11 %d  %+%d   % %d   %-%d   %ll%d %123%d";
    out3 = "%11 1  %+2   % 3   %-4   %ll5 %1236";
    a = 1, b = 2, c = 3, d = 4, e = 5, f = 6;
    hw_sprintf(out1, format, a, b, c, d, e, f);
    check_out3();


    printf("%i/%i tests not passed\n%i/%i tests OK\n", errors, errors + passes, passes, errors + passes);
    return 0;
}
