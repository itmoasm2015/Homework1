global hw_sprintf

section .text

    ; flags for processing number
    ; should current symbol be processed as a part of number format sequence
    FORMAT_SEQUENCE    equ    1
    ; add plus symbol to non-negative numbers
    ALWAYS_PLUS        equ    1 << 2
    ; place space at first position if there's no sign
    FIRST_SPACE        equ    1 << 3
    ; align number to left side
    ALIGN_LEFT     equ        1 << 4
    ; extend number to required size by adding zeros
    FILL_ZEROS         equ    1 << 5
    ; does number take 64 bit?
    FLAG_LONG          equ    1 << 6
    ; does number in two's complinet
    FLAG_UNSIGNED      equ    1 << 7
    ; have flags read?
    FLAGS_ENDED        equ    1 << 8

    ; converts number to string
    ;
    ; edi is corrupted at the time of return
    ;
    ; @param eax stores the flags
    ; @param edi the number to be converted
    ; @param ebx pointer to char* for string
    ; @param esi number's width, 0 if not set
    itoa:
        push edx
        push ecx

        test eax, FLAG_UNSIGNED
        jnz .to_decimal_str
        test edi, 0x80000000      ; is negative?
        jz .to_decimal_str
        ; convert from two's compliment & write '-' to out
        mov byte [ebx], '-'
        inc ebx
        not edi
        inc edi
    ; write decimal string to stack
    .to_decimal_str:
        push eax
        mov ecx, esp ; end of number string in stack
        mov eax, edi
        mov edi, 10
        dec esp
        .loop:
            xor edx, edx
            div edi
            add edx, '0'
            mov byte [esp], dl
            dec esp
            cmp eax, 0
            jne .loop
        mov eax, [ecx]
    ; read characters in back order from stack & write to output
        inc esp
        mov dl, byte [esp]
        .loop1:
            mov byte [ebx], dl
            inc ebx
            inc esp
            mov dl, byte[esp]
            cmp esp, ecx
            jne .loop1
        add esp, 4    ; erase flags in stack

        pop ecx
        pop edx
        ret

    ; void hw_sprintf(char * out, const char * format, ...)
    ;
    ; eax is for flags
    ; ebx is for address of out string
    ; ecx is for address of format string
    ; edx is for current symbol
    ; edi is for argument offset
    ; esi is for minimal width of a number
    ;
    ; @param out pointer to out string
    ; @param format pointer to format string
    hw_sprintf:
        push ebp
        push esi
        push edi
        push ebx

        mov ebx, [esp + 20]    ; out
        mov ecx, [esp + 24]    ; format
        lea edi, [esp + 28]
        xor eax, eax           ; flags register
        xor edx, edx
    .process_next:
        mov dl, byte [ecx]
        cmp edx, 0
        je .done
        cmp edx, '%'
        je .percent
        mov [ebx], edx
        inc ebx
        inc ecx
        jmp .process_next

    .process_format:
        mov dl, byte [ecx]
        cmp edx, '+'
        je .plus
        cmp edx, '-'
        je .minus
        cmp edx, ' '
        je .space
        cmp edx, '0'
        je .zero
        or eax, FLAGS_ENDED
        cmp edx, 'u'
        je .print_unsigned
        cmp edx, 'l'
        je .print_long
        cmp edx, 'd'
        je .print_int
        sub edx, '0'
        cmp edx, 10
        jl .number_width
        jmp .incorrect_sequence

    .print_unsigned:
        or eax, FLAG_UNSIGNED
        jmp .print_int
    .print_long:
        ; make sure there's second 'l'
        inc ecx
        mov edx, [ecx]
        cmp edx, 'l'
        jne .incorrect_sequence
        or eax, FLAG_LONG
        ; TODO
        xor eax, eax
        inc ecx
        jmp .process_next
    .print_int:
        add  esp, 4           ; erase address of format sequence start, no need anymore
        push edi
        mov edi, [edi]
        call itoa
        pop edi
        add edi, 4
        xor eax, eax
        inc ecx
        jmp .process_next
    .number_width:
        imul esi, 10
        add esi, edx
        inc ecx
        jmp .process_format
    .plus:
        test eax, FLAGS_ENDED
        jnz .incorrect_sequence
        or eax, ALWAYS_PLUS
        inc ecx
        jmp .process_format
    .minus:
        test eax, FLAGS_ENDED
        jnz .incorrect_sequence
        or eax, ALIGN_LEFT
        inc ecx
        jmp .process_format
    .space:
        test eax, FLAGS_ENDED
        jnz .incorrect_sequence
        or eax, FIRST_SPACE
        inc ecx
        jmp .process_format
    .zero:
        test eax, FLAGS_ENDED
        jnz .incorrect_sequence
        or eax, FILL_ZEROS
        inc ecx
        jmp .process_format

    .percent:
        test eax, FORMAT_SEQUENCE
        jnz .incorrect_sequence   ; '%' in formatting sequence
        xor eax, eax
        xor esi, esi
        or eax, FORMAT_SEQUENCE
        push ecx                  ; start of format sequence is now in stack
        inc ecx
        jmp .process_format

    .incorrect_sequence:
        xor eax, eax
        pop esi                   ; start of incorrect sequence
        .loop2:
            mov dl, byte [esi]
            mov [ebx], dl
            inc ebx
            inc esi
            cmp esi, ecx
            jne .loop2
        jmp .process_next

    .done:
        mov [ebx], byte 0         ; end of string
        lea esp, [ebp - 0x3C]     ; place in the stack before 4 first pushes
        pop ebx
        pop edi
        pop esi
        pop ebp
        ret
