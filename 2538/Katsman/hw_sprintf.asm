global hw_sprintf

section .text

PLUS_FLAG equ 1
SPACE_FLAG equ 2
ALIGN_FLAG equ 4
ZERO_FLAG equ 8
flags equ 16
flags equ 32
flags equ 64
flags equ 128
flags equ 256

hw_sprintf:
    push ebp
    mov ebp, esp
    push esi
    push eax
    push ecx

    mov eax, [ebp + 8] ; eax contains our out string
    mov ebx, [ebp + 12] ; ebx contains format string
    mov ecx, [ebp + 16] ; ecx contains pointer on first argument


    
.end:
    pop ecx
    pop eax
    pop esi
    pop ebp
    ret
