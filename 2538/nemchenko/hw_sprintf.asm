%define format esi
%define out_buf ebx
%define cur_char al
%define cur_low_bits [ebp]
%define cur_high_bits [ebp + 4]
%define begin_format edi
%define cur_number ebp
section .text

;void hw_sprintf(char *out_buf, char const *format, ...);
global hw_sprintf

hw_sprintf:
    push ebp
    lea  ebp, [esp + 8]
    push ebx
    push esi
    push edi

    ; ebp --> out_buf
    ; ebp + 4 --> format
    mov out_buf, [ebp]
    mov format, [ebp + 4]

    ; ebp --> first argument
    lea ebp, [ebp + 8]

    cld
    .while_format_not0:
        mov [out_buf], byte 0
        xor eax, eax
        mov begin_format, format
        lodsb                                  ; cur_char = *(format++)

        cmp cur_char, 0                        
        je  .end_format_not0                   ; if (cur_char == 0) break;

        cmp cur_char, '%'                      ; if (cur_char != '%') just_print & continue
        jne .just_print

        ; cur_char == '%'
        lodsb                                  ; cur_char = *(format++)

        mov [flags], byte 0
        mov [field_width], byte 0

        call set_flags
        call parse_field_width

        ; current state: %([0-+ ]*)([1-9][0-9]*)?
        ; if next will be %, just ignored flags and field_width
        cmp cur_char, '%'
        je .just_print

        cmp cur_char, 'l'
        jne .out_number

        lodsb                                   ; cur_char = *(format++)
        cmp cur_char, 'l'
        jne .print_incorrect_format             ; %[smth]l

        lodsb                                   ; cur_char = *(format++)
        or [flags], byte size8_flag             ; %[smth]ll

        .out_number:
            cmp cur_char, 'u'
            jne .out_signed_number

            ; %[smth]u
            .out_unsigned_number:
                test [flags], byte size8_flag
                jnz .get_unsigned_long_long
                jmp .get_unsigned_int

            ; %[smth]!u
            .out_signed_number:
                cmp cur_char, 'd'
                je .out_signed_d_number
                cmp cur_char, 'i'
                je .out_signed_d_number
                jmp .print_incorrect_format

                .out_signed_d_number:            ; %[flags]u[i|d]
                    test [flags], byte size8_flag
                    jnz .get_signed_long_long
                    jmp .get_signed_int

        ; for all get_* 
        ; push low bits
        ; push high bits
        ; go to next number
        ; call num_to_str
        ;
        ; for int & uint
        ;    convert to uint64
        ;    high bits = 00..00
        .get_unsigned_long_long:
            push dword cur_low_bits
            push dword cur_high_bits
            add  cur_number, 8                   ; go to next number
            jmp .print_number

        .get_unsigned_int:
            push dword cur_low_bits
            push dword 0
            add  cur_number, 4                   ; go to next number
            jmp .print_number

        .get_signed_long_long:
            cmp cur_high_bits, dword 0 
            jge .next_get_signed_long_long

            or  [flags], byte negative_flag      ; set flag if number < 0
            ; number = abs(number)
            not dword cur_low_bits
            not dword cur_high_bits
            inc dword cur_low_bits
            ; if low bits == 0..0
            ; ~(low bits) == 1..1
            ; we must add carry to high bits
            adc cur_high_bits, dword 0 

            .next_get_signed_long_long:
                push dword cur_low_bits
                push dword cur_high_bits
                add  cur_number, 8              ; go to next number
                jmp  .print_number

        .get_signed_int:
            cmp cur_low_bits, dword 0 
            jge .next_get_signed_int
            or  [flags], byte negative_flag     ; set neg_flag if number < 0
            ; number = abs(number)
            not  dword cur_low_bits
            inc  dword cur_low_bits             

            .next_get_signed_int:
                push dword cur_low_bits
                push dword 0
                add  cur_number, 4              ; go to next number
                jmp .print_number

        .print_number:
            ; on stack:
            ;   high bits
            ;   low bits
            call num_to_str
            call print_num_with_padding
            add  esp, 8                         ; pop 2 arguments
            jmp .while_format_not0


        .print_incorrect_format:
            dec format
            .while_format_note_beg:
                cmp begin_format, format
                je  .while_format_not0          ; if (begin_format == format) continue
                mov eax, [begin_format]
                mov [out_buf], eax              ; *out = *begin_format;
                inc begin_format                ; begin_format++
                inc out_buf                     ; out++
                jmp .while_format_note_beg
                

        .just_print:
            mov [out_buf], cur_char
            inc out_buf
            jmp .while_format_not0

    .end_format_not0:


    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

; void set_flags()
; format saved in esi
set_flags:
    .while_parse_flags:
        cmp cur_char, '+'
        je .case_plus_flag

        cmp cur_char, '-'
        je .case_minus_flag

        cmp cur_char, ' '
        je .case_space_padding_flag

        cmp cur_char, '0'
        je .case_zero_padding_flag

        ret

        .case_plus_flag:
            or  [flags], byte plus_flag
            jmp .next

        .case_minus_flag:
            or  [flags], byte minus_flag
            jmp .next

        .case_space_padding_flag:
            or  [flags], byte space_padding_flag
            mov [sign],  byte ' '
            jmp .next

        .case_zero_padding_flag:
            or [flags], byte zero_padding_flag
            jmp .next

        .next:
            lodsb                          ; cur_char = *(format++)
            jmp .while_parse_flags

; void parse_field_width()
; format saved in esi
parse_field_width:
    push edi
    mov [field_width], dword 0
    .while_parse_field_width:
        cmp cur_char, '9'
        jg .end
        cmp cur_char, '0'
        jl .end

        ; cur_char >= '0' && cur_char <= '9'
        mov edi, [field_width]
        imul edi, 10                ; *field_width *= 10
        sub cur_char, '0'
        add edi, eax                ; *field_width += (cur_char - '0') ; add edi, cur_char doesn't work =(
        mov [field_width], edi      ; *field_width = *field_width * 10 + (cur_char - '0');

        lodsb                       ; cur_char = *(format++)
        jmp .while_parse_field_width

    .end:
        pop edi
        ret

; int num_to_str(unsigned long long value)
; print string representation of value in reverse order to str_repr
; set len_str_repr = len(str_rep)
; stack:
;   return address
;   high bits
;   low bits
num_to_str:
    push ebp
    lea ebp, [esp + 8]
    push esi
    push ebx
    push edx
    
    mov [len_str_repr], dword 0
    mov ecx, 10
    mov esi, str_repr
    ; ebp  --> high bits
    ; ebp + 4 --> low bits
    mov edx, [ebp]
    mov eax, [ebp + 4]

    .while_num_not0:
        cmp eax, 0
        jne .not0
        cmp edx, 0
        je .end_while_num_not0

        .not0:

        ; 64 bits divide
        push eax
        mov eax, edx    ; eax = high bits
        xor edx, edx
        div ecx         ; get high 32 bits of quotient
        xchg eax, [esp] ; store them on stack, get low 32 bits of dividend
        div ecx         ; get low 32 bits of quotient

        ; *(esi++) = number % 10 + '0'
        mov ebx, edx
        add ebx, byte '0'
        mov [esi], ebx      
        inc esi                    

        pop edx         ; 64-bit quotient in edx:eax now
        inc dword [len_str_repr]

        jmp .while_num_not0

    .end_while_num_not0:

    pop edx
    pop ebx
    pop esi
    pop ebp
    ret

; void print_num_with_padding()
; print str_repr to out_buf in right order
; with padding '0' or ' '  and if needed with sign '+' or '-' 
print_num_with_padding:
    push eax
    mov eax, [field_width]
    mov [padding_size], eax
    mov eax, [len_str_repr]
    sub [padding_size], eax   ; int padding_size = field_width - len_number;

    ; al = plus_flag | space_padding_flag | negative_flag
    mov al, byte plus_flag
    or  al, byte space_padding_flag
    or  al, byte negative_flag

    test [flags], al         ; if (flags & (plus_flag | space_padding_flag | negative_flag)) {
    jz .without_dec
    dec dword [padding_size] ; we have to print sign, therefore padding decrement

    .without_dec:

    cmp [padding_size], dword 0
    jle .just_print_number

    ;if (padding_size > 0) {
    mov al, byte minus_flag
    test [flags], al         
    jz .print_without_minus_flag

    ;if (flags & minus_flag) {
    call print_sign
    call print_number

    mov al, ' '
    call print_padding  ; if minus_flag : [+|-][number][padding ' ']
    pop eax
    ret

    ;if (!(flags & minus_flag)) {
    .print_without_minus_flag:
        test [flags], byte zero_padding_flag
        jnz .print_with_zero_padding

        ; padding = ' '
        ; [padding ' '][+|-][number]
        mov al, ' '
        call print_padding
        call print_sign
        jmp .end_print_with_padding

        ; if (flags & zero_padding_flag) 
        .print_with_zero_padding:
            ; padding = '0'
            ; [+|-][padding '0'][number]
            call print_sign
            mov cur_char, '0'
            call print_padding
            jmp .end_print_with_padding

    ; if (padding_size <= 0) print without padding
    .just_print_number:
        call print_sign

    .end_print_with_padding:
        call print_number
        pop eax
        ret

; void print_sign()
; print in out_buf sign of number if needed
; al = sign_symbol[' ' | '0']
print_sign:
    test [flags], byte negative_flag
    jnz .case_neg_flag

    test [flags], byte plus_flag
    jnz .case_pl_flag

    test [flags], byte space_padding_flag
    jnz .case_sp_flag

    ret

    .case_neg_flag:
        mov [out_buf], byte '-' 
        jmp .end_sign
    .case_pl_flag:
        mov [out_buf], byte '+' 
        jmp .end_sign
    .case_sp_flag:
        mov [out_buf], byte ' ' 
        jmp .end_sign

    .end_sign:
        inc out_buf
        ret

; void print_number()
; print in out_buf str_repr[len_str_repr - 1 .. 0]
print_number:
    push eax
    push edi
    .while_len_number_g_0: ; while (len_number > 0) {
        cmp [len_str_repr], dword 0
        jz .end_p_num
        dec dword [len_str_repr]
        mov edi, str_repr
        add edi, [len_str_repr]  ; edi = str_repr + len_str_repr
        mov al, byte [edi]       
        mov [out_buf], al        ; *out = str_repr[len_str_repr]; 
        inc out_buf
        jmp .while_len_number_g_0

    .end_p_num:
        pop edi
        pop eax
        ret

; void print_padding()
; al = padding_symbol[' ' | '0']
print_padding:
    .while_padding_size:
        mov [out_buf], al
        inc out_buf
        dec dword [padding_size]
        cmp [padding_size], dword 0
        jz .end_print_with_padding
        jmp .while_padding_size
    .end_print_with_padding:
    ret

section .bss
    ; size8_flag --> %ll or %ull
    flags:        resb 1
    field_width:  resd 1
    cur_digit:    resb 1
    str_repr:     resb 25
    len_str_repr: resd 1
    padding_size: resd 1
    sign:         db 0

section .rodata
    plus_flag:          equ 0x1
    minus_flag:         equ 0x2
    space_padding_flag: equ 0x4
    zero_padding_flag:  equ 0x8
    size8_flag:         equ 0x10
    negative_flag:      equ 0x20
