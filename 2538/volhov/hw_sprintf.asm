global hw_sprintf

section .text

%define flag_plus  1 << 0
%define flag_space 1 << 1
%define flag_minus 1 << 2
%define flag_zero  1 << 3


;;; void hw_sprintf(char *out, char const *format, ...)
hw_sprintf:
        push    ebp
        mov     ebp, esp

        ;; save registers
        push    edi
        push    ebx

        mov     edi, [ebp+8]    ; edi - destination buffer, current symbol
        mov     esi, [ebp+12]   ; esi - source buffer, current symbol

        ;; save current argument pointer
        add     ebp, 12
        mov     [arg_pointer], ebp
        sub     ebp, 12

        xor     edx, edx
.start_parsing:
        xor     dL, dL
        mov     dL, byte [esi]
        cmp     dL, '%'
        jz     .parse_control  ; compare it with %, jmp to handler
        movsb                   ; else just copy current char
        jmp     .end_output
.parse_control:
        inc     esi
.end_parsing:
.end_output:
        test    dL, dL
        jnz     .start_parsing
.end:
        ;; restore
        pop     ebx
        pop     edi

        mov     esp, ebp
        pop     ebp
        ret

section .data
arg_pointer:    resw 2
teststring:     db 'mamku_lublu))', 0
printout:       db 'hw_sprintf: d', 10, 0
