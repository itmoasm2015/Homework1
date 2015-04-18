global hw_sprintf

%define PLUS_FLAG 1
%define ALIGN_LEFT_FLAG 1 << 1
%define SPACE_FLAG 1 << 2
%define LONG_LONG_FLAG 1 << 3
%define ZERO_FLAG 1 << 4
%define UNSIGNED_FLAG 1 << 5
%define NEGATIVE_FLAG 1 << 6

%define MINUS '-'
%define ASCII_CONST 48

%define set_flag(f) or ebx, f
%define test_flag(f) test ebx, f

section .text

; void hw_swprintf(char* out, char const* format, ...)

hw_sprintf:                     ; save the status of the registers
    push ebx
    push ebp
    push esi
    push edi

    mov edi, [esp + 32 - 12]    ; out
    mov esi, [esp + 32 - 8]     ; format
    lea ebp, [esp + 32 - 4]     ; arguments

.process:                       ; process characters one at a time
    cmp byte[esi], '%'          ; check if we met a special character
    je .format
    movsb
    cmp byte[esi], 0            ; put the character into out
    je .return
    jne .process

.format:                        ; store esi state in case format is incorrect
    push esi                    ; and null out the registers
    xor ebx, ebx
    xor edx, edx
    xor eax, eax
    inc esi

.parse_flags:
    lodsb                       ; load a byte into al and set corresponding flags

    cmp al, '+'
    je .set_plus_flag

    cmp al, '-'
    je .set_minus_flag

    cmp al, ' '
    je .set_space_flag

    cmp al, '0'
    je .set_zero_flag

.get_width:                     ; if the character is not a digit, skip this step
    cmp al, '0'
    jl .break_width_loop
    cmp al, '9'
    jg .break_width_loop

    imul edx, 10                ; calculate the width here
    sub eax, ASCII_CONST
    add edx, eax

    lodsb
    jmp .get_width

.break_width_loop:
    ;push edx

.get_size:
    dec esi                     ; fix an extra lodsb instruction moving the pointer forward
    cmp word[esi], 'll'         ; check if we met a long long specifier
    jne .get_type

    add esi, 2                  ; move the pointer away from 'll' specifier
    set_flag(LONG_LONG_FLAG)    ; and set the corresponding flag

.get_type:                      ; parse the type symbol
    lodsb

    cmp al, 'u'
    je .set_unsigned_flag
    cmp al, 'i'
    je .format_parse_finished
    cmp al, 'd'
    je .format_parse_finished
    cmp al, '%'
    je .print_percent

    jmp .malformed_format

.set_unsigned_flag:             ; actually set the flags
    set_flag(UNSIGNED_FLAG)
    jmp .format_parse_finished

.set_plus_flag:
    set_flag(PLUS_FLAG)
    jmp .parse_flags

.set_minus_flag:
    set_flag(ALIGN_LEFT_FLAG)
    jmp .parse_flags

.set_space_flag:
    set_flag(SPACE_FLAG)
    jmp .parse_flags

.set_zero_flag:
    set_flag(ZERO_FLAG)
    jmp .parse_flags

.format_parse_finished:
    pop eax
    jmp .output

.malformed_format:
    pop esi                     ; restore position in string to the start of command sequence
    movsb                       ; move % to out and keep processing the string
    jmp .process

.output:
    test_flag(LONG_LONG_FLAG)   ; check if the number is int64
    jnz .int64

.int32:                         
    xor edx, edx
    mov eax, [ebp]
    add dword ecx, 4

    test_flag(UNSIGNED_FLAG)    ; check if the number is unsigned
    jnz .done

    cmp eax, 0
    jl .negative_int32
    jmp .done

.negative_int32                 ; if the number is negative
    set_flag(NEGATIVE_FLAG)     ; set the flag and flip its sign
    neg eax
    jmp .done

.int64:

.done:
    call put_first_character    ; print the requested character before the number

.decimal:
    inc esi
    xor ecx, ecx                 ; null out the counter of the number's length

.unsigned:

.parse_number:                  ; the loop that
    xor edx, edx
    mov ebx, 10                 ; parses the number digit by digit
    div ebx
    add edx, ASCII_CONST        ; add the constant to turn the digit
    push edx                    ; into the corresponding character
    inc ecx                     ; and push it onto the stack
    test eax, eax               ; if the dividend still is not zero,
    jnz .parse_number           ; start over

.reverse_get:                   ; build the number from the stack
    pop eax
    mov [edi], eax              ; put a digit into out
    inc edi
    dec ecx                     ; reduce the number's length
    test ecx, ecx               ; if it is not zero
    jnz .reverse_get            ; keep getting digits
    jmp .process                ; else

.print_percent                  ; command sequence contains the '%' character
    add esp, 4                  ; no need to store width anymore
    stosb                       ; move % to output, AL -> EDI
    jmp .process

.return:                        ; restore the status of the registers
    pop edi
    pop esi
    pop ebp
    pop ebx
    ret                         ; and finish

;_______________________________

put_first_character:            ; subroutine that prints requested characters
    test_flag(NEGATIVE_FLAG)    ; before the number
    jnz .put_minus              ; according to the flags

    test_flag(PLUS_FLAG)
    jnz .put_plus

    test_flag(SPACE_FLAG)
    jnz .put_space
    jmp .ret

.put_minus:
    mov byte [edi], '-'
    inc edi
    jmp .ret

.put_plus:
    mov byte [edi], '+'
    inc edi
    jmp .ret

.put_space:
    mov byte [edi], ' '
    inc edi
    jmp .ret

.ret:
    ret