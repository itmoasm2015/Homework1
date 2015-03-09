#ifndef _HOMEWORK_1_H_
#define _HOMEWORK_1_H_

#ifdef __cplusplus
extern "C"
#endif
__attribute__((cdecl))
//void hw_sprintf(char *out, char const *format, ...);
int hw_strlen(char *s);
int hw_itoa(int a, char *out);
int hw_luitoa(unsigned long long a, char *out);

#endif
