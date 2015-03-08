global hw_sprintf

section .text

    ; flags for processing number
    ; should current symbol be processed as a part of number format sequence
    FORMAT_SEQUENCE    equ    1
    ; add plus symbol to non-negative numbers
    PLACE_PLUS        equ    1 << 2
    ; place space at first position if there's no sign
    PLACE_SPACE        equ    1 << 3
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
    ; should we fill string to reach minimal number width?
    FILL               equ    1 << 9
    ; do we have to place following symbols?
    PLUS               equ    1 << 10
    MINUS              equ    1 << 11
    SPACE              equ    1 << 12
    ; if one symbol was written directly to out
    DEC_COUNT          equ    1 << 13

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
        push eax
        mov ecx, esp ; end of number string in stack

        test eax, FLAG_UNSIGNED
        jnz .add_plus
        test edi, 0x80000000      ; is negative?
        jnz .add_minus
        jmp .add_plus              ; checks flags & adds plus if has to
    ; depends on FILL_ZEROS flag we should write sign as the first symbol of string
    ; or as the symbol before the first significant figure
    .add_minus:
        not edi
        inc edi
        test eax, FILL_ZEROS
        jz .add_minus_flag
        mov byte [ebx], '-'
        inc ebx
        or eax, DEC_COUNT
        jmp .to_decimal_str
    .add_minus_flag:
        or eax, MINUS
        jmp .to_decimal_str
    .add_plus:
        test eax, PLACE_PLUS
        jz .add_space
        test eax, FILL_ZEROS
        jz .add_plus_flag
        mov byte [ebx], '+'
        inc ebx
        or eax, DEC_COUNT
        jmp .to_decimal_str
    .add_plus_flag:
        or eax, PLUS
        jmp .to_decimal_str
    .add_space:
        test eax, PLACE_SPACE
        jz .to_decimal_str
        or eax, SPACE
        jmp .to_decimal_str
    ; write decimal string to stack
    .to_decimal_str:
        mov [ecx], eax
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
        test eax, PLUS
        jnz .place_plus
        test eax, MINUS
        jnz .place_minus
        test eax, SPACE
        jnz .place_space
        jmp .done_placing
    .place_plus:
        mov byte [esp], '+'
        dec esp
        jmp .done_placing
    .place_minus:
        mov byte [esp], '-'
        dec esp
        jmp .done_placing
    .place_space:
        mov byte [esp], ' '
        dec esp
        jmp .done_placing
    .done_placing:
        mov edx, ecx      ; let's find out should we add spaces or zeros
        sub edx, esp
        cmp edx, esi
        ja .write
        ; let's try to add some spaces or zeros
        or eax, FILL
        sub esi, edx
        inc esi
        ; one symbol may be written to out
        test eax, DEC_COUNT
        jnz .dec_esi
        jmp .continue
    .dec_esi:
        dec esi
        jz .write
    .continue:
        test eax, ALIGN_LEFT
        jnz .write
        mov edx, ' '
        test eax, FILL_ZEROS
        jz .call_fill
        mov edx, '0'
        mov eax, [ecx]
    .call_fill:
        call fill_symb
    ; read characters in reverse order from stack & write to output
    .write:
        inc esp
        mov dl, byte [esp]
        .loop1:
            mov byte [ebx], dl
            inc ebx
            inc esp
            mov dl, byte [esp]
            cmp esp, ecx
            jne .loop1
        add esp, 4      ; erase flags in stack

        test eax, ALIGN_LEFT
        jz .done_itoa
        test eax, FILL
        jz .done_itoa
        ; btw, esi still contains desirable number
        mov edx, ' '
        call fill_symb

    .done_itoa:
        pop ecx
        pop edx
        ret

    ; places esi symbols with code edx in out string, esi > 0
    ;
    ; @param esi number of symbols to be written
    ; @param edx code of symbol to place
    ; @param ebx pointer to current position in out string
    fill_symb:
        .loop3:
            mov byte [ebx], dl
            inc ebx
            dec esi
            jnz .loop3
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
    .digit:
        cmp edx, '9'             ; <= '9'
        ja .incorrect_sequence
        cmp edx, '0'             ; >= '0'
        jae .number_width
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
        sub edx, '0'
        imul esi, 10
        add esi, edx
        inc ecx
        jmp .process_format
    .plus:
        test eax, FLAGS_ENDED
        jnz .incorrect_sequence
        or eax, PLACE_PLUS
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
        or eax, PLACE_SPACE
        inc ecx
        jmp .process_format
    .zero:
        test eax, FLAGS_ENDED
        jnz .digit
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
        mov dl, byte [ecx]
        cmp edx, '%'              ; .incorrect_sequence prints two '%', so prevent it
        jne .process_format
        add esp, 4                ; erase start of sequence
        mov [ebx], edx
        inc ebx
        inc ecx
        xor eax, eax
        jmp .process_next

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
