#include "hw1.h"
#include <cstdio>

int main()
{
  char string[1000002];

  hw_sprintf(string,"test long: %llu %lld %lld", (long long) -1, 1234567890123456, (long long) -17);
  printf("%s\r\n %llu %lld -17\r\n",string, (long long) -1, 1234567890123456);
  hw_sprintf(string, "50%%");
  printf("%s\r\n",string);
  hw_sprintf(string, "%+08u=%-0 8u", 1234, 1234);
  printf("%s\r\n",string);
  hw_sprintf(string,"test int: % l%d,  %+++8u .% u %wtf %u",-1,97,55,-1);
  printf("%s\r\n -1 97 55 %u\r\n",string,-1);
  hw_sprintf(string, "%+5u", 51);
  printf("%s\r\n",string);
  hw_sprintf(string, "%+05u", 51);
  printf("%s\r\n",string);
  hw_sprintf(string, "test bad: %wtf %+10-0000d %ll", 123, 2, 3, 4);
  printf("%s\r\n",string);
  //hw_sprintf(string, "%1000000d", 1);
  //printf("%s\r\n",string);
 
  return 0;
}
