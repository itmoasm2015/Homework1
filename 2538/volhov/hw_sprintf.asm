global hw_sprintf

section .text

%define offset_plus  0
%define offset_space 1
%define offset_minus 2
%define offset_zero  3


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
        jz      .parse_control   ; compare it with %, jmp to handler
        movsb                   ; else just copy current char
        jmp     .end_output
.parse_control:
        xor     eax, eax        ; eax will hold flags information
.parse_flags:
        inc     esi
        xor     dL, dL
        mov     dL, byte [esi]
        cmp     dL, '+'
        jz      .parse_plus
        cmp     dL, ' '
        jz      .parse_space
        cmp     dL, '-'
        jz      .parse_minus
        cmp     dL, '0'
        jz      .parse_zero
        jmp     .end_parsing
.parse_plus:
        bts     eax, offset_plus
        jmp     .parse_flags
.parse_space:
        bts     eax, offset_space
        jmp     .parse_flags
.parse_minus:
        mov     ebx, eax
        and     ebx, offset_zero
        cmp     ebx, 0
        jz      .parse_minus_left
        xor     ebx, ebx
        btc     eax, offset_zero
        jmp     .parse_flags
.parse_minus_left:
        bts     eax, offset_minus
        jmp     .parse_flags
.parse_zero:
        bt      eax, offset_minus
        jc      .parse_zero_left
        bts     eax, offset_zero
.parse_zero_left:
        jmp     .parse_flags
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
