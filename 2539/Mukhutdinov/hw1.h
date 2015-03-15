#ifndef __FLF_CTDDEV_ASM_HW_1
#define __FLF_CTDDEV_ASM_HW_1

#ifdef __cplusplus
extern "C"
#endif
__attribute__((cdecl))
char* hw_ntoa(void* np, char* out, int flags, int minlength);

#ifdef __cplusplus
extern "C"
#endif
__attribute__((cdecl))
void hw_sprintf(char* out, char const* format, ...);

#endif
