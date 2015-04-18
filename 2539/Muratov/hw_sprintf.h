#ifndef HW_SPRINTF
#define HW_SPRINTF

#ifdef __cplusplus
extern "C"
#endif

__attribute__((cdecl))
void hw_sprintf(char *out, char const *format, ...);

#endif