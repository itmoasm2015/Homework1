; Most functions do not comply the cdecl calling convention
; Parameters are stored (and the result is returned) in the registers
; for better performance (close to borland fastcall)
; Actually hw_sprintf is the only cdecl procedure
%define MAXINT 2147483647
%define FLAG_PLUS  1
%define FLAG_SPACE 2
%define FLAG_MINUS 4
%define FLAG_ZERO  8
%define FLAG_LONG 16
global main

; TODO remove it (as it’s for debug purposes only)
extern puts

section .text
; procedure printing an unsigned long into a buffer.
; Parameters:
; edx:eax — the number
; edi — pointer to the buffer
; return value: eax — length of the string (without the terminating null)
; discards eax, ecx, edx
ulong_to_string:
    push    edi
    push    ebx
    ; copy the string representation of the number to the stack
    push    byte 0
    mov     ecx, 10
    .iterate
        push eax
        mov  eax, edx
        xor  edx, edx
        div  ecx         ; divide the high-order half first
        mov  ebx, eax
        pop  eax         ; then divide the low-order half
        div  ecx
        xchg ebx, edx    ; combine the quotents
        add  bl, '0'
        dec  esp
        mov  [esp], bl
        cmp  eax, 0
        jne  .iterate

    ; copy string on stack to [edi]
    .strcpy
        mov  dl, [esp]
        inc  esp
        mov  [edi], dl
        inc  edi
        cmp  dl, 0
        jne  .strcpy

    lea     eax, [edi - 1]

    add     esp, 3
    pop     ebx
    pop     edi
    sub     eax, edi
    ret

; function printing a signed long number into a buffer.
; Parameters:
; edx:eax — the number
; edi — pointer to the buffer
; return value: eax — length of the string (without the terminating null)
; discards eax, ecx, edx
long_to_string:
    cmp     edx, 0
    jge     ulong_to_string
    not     edx
    cmp     eax, 0    ; handle overflow when the low-order half is zero
    jne     .notzero
    inc     edx
    .notzero
    neg     eax
    mov     [edi], byte '-'
    inc     edi
    call    ulong_to_string
    inc     eax
    dec     edi
    ret

; procedure printing an unsigned int into a buffer.
; Parameters:
; eax — the number
; edi — pointer to the buffer
; return value: eax — length of the string (without the terminating null)
; discards eax, ecx, edx
uint_to_string:
    push    edi
    ; copy the string representation of the number to the stack
    push    byte 0
    mov     ecx, 10
    .iterate
        xor  edx, edx
        div  ecx
        add  dl, '0'
        dec  esp
        mov  [esp], dl
        cmp  eax, 0
        jne  .iterate

    ; copy string on the stack to [edi]
    .strcpy
        mov  dl, [esp]
        mov  [edi], dl
        inc  esp
        inc  edi
        cmp  dl, 0
        jne  .strcpy

    lea     eax, [edi - 1]

    add     esp, 3
    pop     edi
    sub     eax, edi
    ret


; procedure printing an integer into a buffer.
; Parameters:
; eax — the number
; edi — pointer to the buffer
; return value: eax — length of the string (without the terminating null)
; discards eax, ecx, edx
int_to_string:
    cmp     eax, 0
    jge     uint_to_string
    neg     eax
    mov     [edi], byte '-'
    inc     edi
    call    uint_to_string
    dec     edi
    ret

main:
    mov     edx, (1<<31)
    mov     eax, 0
    mov     edi, azaza
    call    long_to_string
    add     al, '0'
    push    byte 0
    dec     esp
    mov     [esp], al
    push    azaza
    call    puts
    add     esp, 9


section .bss
azaza:    resb    100
