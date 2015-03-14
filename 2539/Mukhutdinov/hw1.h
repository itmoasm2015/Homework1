#ifndef __FLF_CTDDEV_ASM_HW_1
#define __FLF_CTDDEV_ASM_HW_1

#ifdef __cplusplus
extern "C"
#endif
__attribute__((cdecl))
void hw_uitoa(uint32_t n, char* out);

#ifdef __cplusplus
extern "C"
#endif
__attribute__((cdecl))
void hw_itoa(int n, char* out);


#endif
