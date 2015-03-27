global hw_sprintf

extern printf

section .text

%define offset_plus  0
%define offset_space 1
%define offset_minus 2
%define offset_zero  3
%define offset_recovery 4       ; used for printing bad control sequences directly
%define offset_is_ll 5
%define offset_type 6           ; if 0, int, if 1, unsigned
%define offset_sign 7           ; 0 - geq 0, 1 - le 0

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
        bts     eax, offset_plus
        inc     esi
        jmp     .parse_flags
.parse_space:
        bts     eax, offset_space
        inc     esi
        jmp     .parse_flags
.parse_minus:
        btr     eax, offset_zero
        bts     eax, offset_minus
        inc     esi
        jmp     .parse_flags
.parse_zero:
        bt      eax, offset_minus
        jc      .parse_zero_left
        bts     eax, offset_zero
.parse_zero_left:
        inc     esi
        jmp     .parse_flags
.parse_width:
        xor     ecx, ecx        ; ecx will accumulate width
..loop:
        cmp    dl, '0'
        jl      .parse_size
        cmp    dl, '9'
        jg      .parse_size

        push    eax
        push    edx
        push    ebx

        imul    ecx, 10
        xor     ebx, ebx
        mov     bl, dl
        sub     bl, 48
        add     ecx, ebx

        pop     ebx
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
        je      .end_parsing
        cmp     dl, 'd'
        je      .end_parsing
        cmp     dl, 'u'
        je      .parse_type_u
        cmp     dl, '%'
        je      .parse_type_procent
        jmp     .parse_special_failed
.parse_type_u:
        bts     eax, offset_type
        jmp     .end_parsing
.parse_type_procent:
        xor     eax, eax
        xor     ebx, ebx
        add     esp, 4
        jmp     .regular_copy
.end_parsing:
        add     esp, 4          ; pop the value of recovery point
.output_special:
        bt      eax, offset_type ; if type is unsigned, don't set sign (0 is +)
        jc      .calc_real_width
        bt      eax, offset_is_ll ; if it's long long, set long long sign
        jc      .set_ll_sign
        push    ebp
        mov     ebp, dword [arg_pointer]
        bt      dword [ebp + 4], 31 ; otherwise set sign right here
        pop     ebp
        jnc     .calc_real_width ; if sign is 0, go calc
        bts     eax, offset_sign ; else set sign to 1
        jmp     .calc_real_width
.set_ll_sign:
        push    ebp
        mov     ebp, dword [arg_pointer]
        bt      dword [ebp + 8], 31
        pop     ebp
        jnc     .calc_real_width
        bts     eax, offset_sign
;;; In this part, we parse argument, place each symbol of
;;; it's base-10 representation to int_representation and
;;; calculate width in symbols
.calc_real_width:
        push    ebx
        push    edx
        push    eax
        push    ecx
        push    ebp

        mov     ebx, eax          ; flags now in ebx
        xor     eax, eax
        xor     ecx, ecx
        xor     edx, edx
        mov     ebp, [arg_pointer]

        ;; Copying argument to edx:eax
        bt      ebx, offset_is_ll ; if not long, copy just lower
        jnc     .calc_not_long_move
        mov     edx, dword[ebp+8] ; otherwise higher too
.calc_not_long_move:
        mov     eax, dword[ebp+4]

        ;; Converting to the 2's complement form
        bt      ebx, offset_sign  ; if sign is 0, just skip converting
        jnc     .calc_width_divisions
        bt      ebx, offset_is_ll ; if not long, do operation only for lower
        jnc     .calc_abs_only_lower
        not     edx             ; convert higher bits
.calc_abs_only_lower:
        not     eax             ; convert lower bits
        inc     eax

.calc_width_divisions:
        nop
        nop
        nop

        pop     ebp
        pop     ecx
        pop     eax
        pop     edx
        pop     ebx

;;; recovering
        xor     eax, eax
        xor     ebx, ebx
        inc     esi
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

arg_pointer:            resw 2
dec_repres_length:      resw 2
int_representation:     resb 30

teststring:     db 'mamku_lublu))', 0
printfformat:   db 'debug: %d', 10, 0
printout:       db 'hw_sprintf: d', 10, 0
