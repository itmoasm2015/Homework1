global hw_sprintf

extern printf

section .text

%define offset_plus  0
%define offset_space 1
%define offset_minus 2
%define offset_zero  3
%define offset_recovery 4       ;used for printing bad control sequences directly
%define offset_is_ll 5
%define offset_type_1 6         ;type flag 1
%define offset_type_2 7         ;type flag 2, 00i, 01d, 10u


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

.start_parsing:
        xor     edx, edx
        mov     dl, byte [esi]
        cmp     dl, '%'
        jz      .parse_control  ; compare it with %, jmp to handler
.regular_copy:
        movsb                   ; else just copy current char
        jmp     .end_output

;;; Parsing section, flags do dr
.parse_special_failed:
        pop     esi
        mov     dl, byte [esi]
        jmp     .regular_copy
.parse_control:
        xor     eax, eax          ; eax will hold flags information
        push    esi
        inc     esi
.parse_flags:
        mov     dl, byte [esi]
        cmp     dl, '+'
        jz      .parse_plus
        cmp     dl, ' '
        jz      .parse_space
        cmp     dl, '-'
        jz      .parse_minus
        cmp     dl, '0'
        jz      .parse_zero
        jmp     .parse_width
.parse_plus:
        bt      eax, offset_plus
        jc      .parse_special_failed
        bts     eax, offset_plus
        inc     esi
        jmp     .parse_flags
.parse_space:
        bt      eax, offset_space
        jc      .parse_special_failed
        bts     eax, offset_space
        inc     esi
        jmp     .parse_flags
.parse_minus:
        bt      eax, offset_minus
        jc      .parse_special_failed
        mov     ebx, eax
        and     ebx, 1 << offset_zero
        cmp     ebx, 0
        jz      .parse_minus_left
        btc     eax, offset_zero
        jmp     .parse_flags
.parse_minus_left:
        bts     eax, offset_minus
        inc     esi
        jmp     .parse_flags
.parse_zero:
        bt      eax, offset_zero
        jc      .parse_special_failed
        bt      eax, offset_minus
        jc      .parse_zero_left
        bts     eax, offset_zero
.parse_zero_left:
        inc     esi
        jmp     .parse_flags
.parse_width:
        xor     ebx, ebx        ; ebx will accumulate width
..loop:
        cmp    dl, '0'
        jl      .parse_size
        cmp    dl, '9'
        jg      .parse_size

        push    eax
        push    edx
        push    ecx

        imul    ebx, 10
        xor     ecx, ecx
        mov     cl, dl
        sub     cl, 48
        add     ebx, ecx

        pop     ecx
        pop     edx
        pop     eax
        inc     esi
        mov     dl, byte[esi]
        jmp     ..loop
.parse_size:
        cmp     dl, 'l'
        jne     .parse_type
        cmp     byte[esi+1], 'l'
        jne     .parse_type
        add     esi, 2
        bts     eax, offset_is_ll
        mov     dl, [esi]
.parse_type:
        cmp     dl, 'i'
        je      .parse_type_i
        cmp     dl, 'd'
        je      .parse_type_d
        cmp     dl, 'u'
        je      .parse_type_u
        cmp     dl, '%'
        je      .parse_type_procent
        jmp     .parse_special_failed
.parse_type_i:
        jmp     .output_special
.parse_type_d:
        bts     eax, offset_type_2
        jmp     .output_special
.parse_type_u:
        bts     eax, offset_type_1
        jmp     .output_special
.parse_type_procent:
        xor     eax, eax
        xor     ebx, ebx
        jmp     .regular_copy
.output_special:
        inc     esi
.end_parsing:
        add     esp, 4          ; pop the value of recovery point
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
printfformat:   db 'debug: %d', 10, 0
printout:       db 'hw_sprintf: d', 10, 0
