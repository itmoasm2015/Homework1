global hw_sprintf

section .text
    ; flags for processing number
    ; should current symbol be processed as a part of number format sequence
    FLAG_CTRL_SEQ    equ    1
    ; add plus symbol to non-negative numbers
    FLAG_PLUS        equ    1 << 2
    ; place space at first position if there's no sign
    FLAG_SPACE        equ    1 << 3
    ; align number to left side
    FLAG_ALIGN_LEFT     equ        1 << 4
    ; extend number to required size by adding zeros
    FLAG_ZEROS         equ    1 << 5
    ; does number take 64 bit?
    FLAG_LONG          equ    1 << 6
    ; does number in two's complinet
    FLAG_UNSIGNED      equ    1 << 7
    ; following flags are internal
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
    ; if cf is true when inc lowest part of long
    CARRY              equ    1 << 14

    ; write number to string
    ;
    ; edi is corrupted at the time of return
    ;
    ; @param eax stores the flags
    ; @param edi is the number to be converted or address of long if FLAG_LONG is set
    ; @param ebx pointer to char* for string
    ; @param esi number's width, 0 if not set
    itoa:
        push edx
        push ecx
        push eax
        mov ecx, esp ; end of number string in stack
        test eax, FLAG_UNSIGNED
        jnz .add_plus
        test eax, FLAG_LONG        ; is negative?
        jz .int_neg_check
        push edi
        mov edi, [edi + 4]         ; highest 32 bits
        test edi, 0x80000000
        jnz .from2compl_long
        jmp .add_plus_long
    .int_neg_check:
        test edi, 0x80000000
        jnz .from2compl_int
        jmp .add_plus              ; checks flags & adds plus if has to
    ; depends on FLAG_ZEROS flag we should write sign as the first symbol of string
    ; or as the symbol before the first significant figure (i.e. last push in stack)
    .from2compl_long:
        mov edi, [esp]
        push ebx
        mov edi, [edi]             ; lowest 32 bits
        not edi
        inc edi
        jnc .no_carry
        or eax, CARRY
    .no_carry:
        mov ebx, [esp + 4]
        mov [ebx], edi
        mov edi, [ebx + 4]         ; highest 32 bits
        not edi
        test eax, CARRY
        jz .no_carry_again
        inc edi
    .no_carry_again:
        mov [ebx + 4], edi
        pop ebx
        pop edi
        jmp .add_minus
    .from2compl_int:
        not edi
        inc edi
    .add_minus:
        test eax, FLAG_ZEROS
        jz .add_minus_flag
        mov byte [ebx], '-'
        inc ebx
        or eax, DEC_COUNT
        jmp .to_decimal_str
    .add_minus_flag:
        or eax, MINUS
        jmp .to_decimal_str
    .add_plus_long:
        pop edi
    .add_plus:
        test eax, FLAG_PLUS
        jz .add_space
        test eax, FLAG_ZEROS
        jz .add_plus_flag
        mov byte [ebx], '+'
        inc ebx
        or eax, DEC_COUNT
        jmp .to_decimal_str
    .add_plus_flag:
        or eax, PLUS
        jmp .to_decimal_str
    .add_space:
        test eax, FLAG_SPACE
        jz .to_decimal_str
        or eax, SPACE
        jmp .to_decimal_str
    ; write decimal string to stack
    .to_decimal_str:
        mov [ecx], eax
        mov edx, eax    ; temporary place for flags
        mov eax, edi
        mov edi, 10
        test edx, FLAG_LONG
        jnz .push_long
        jmp .push_int
    .push_done:
        mov eax, [ecx]
        test eax, PLUS
        jnz .FLAG_PLUS
        test eax, MINUS
        jnz .place_minus
        test eax, SPACE
        jnz .FLAG_SPACE
        jmp .done_placing
    .FLAG_PLUS:
        mov byte [esp], '+'
        dec esp
        jmp .done_placing
    .place_minus:
        mov byte [esp], '-'
        dec esp
        jmp .done_placing
    .FLAG_SPACE:
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
        test eax, FLAG_ALIGN_LEFT
        jnz .write
        mov edx, ' '
        test eax, FLAG_ZEROS
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

        test eax, FLAG_ALIGN_LEFT
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

    ; converts 32-bit number in characters and places them in stack
    ; so first symbol in stack is first digit of number
    ; don't declare as a function because call spoils all the stack magic
    ;
    ; corrupts edx
    ; corrupts eax
    ; decrease esp
    ;
    ; @param eax number to be converted
    ; @param edi base of numeral system
    .push_int:
        dec esp
        .loop:
            xor edx, edx
            div edi
            add edx, '0'
            mov byte [esp], dl
            dec esp
            cmp eax, 0
            jne .loop
        jmp .push_done

    ; same as .push_int but for 64-bit number, also eax is address
    ;
    ; corrupts edx
    ; corrupts eax
    ; corrupts edi
    ; decrease esp
    ;
    ; @param eax address to number to be converted
    ; @param edi base of numeral system
    ; @param ebx out string address
    .push_long:
        mov [ebx], edi        ; we'll use eax and edi as parts of number
                              ; and divisor will be in memory
        mov edi, [eax]        ; lowest 32 bits = l
        mov eax, [eax + 4]    ; highest 32 bits = h
        dec esp
        .loop4:
            xor edx, edx
            div dword [ebx]   ; edx = h % 10
            xchg edi, eax     ; edx:eax = (h % 10) * 2 ** 32 + l
            div dword [ebx]
            add edx, '0'
            mov byte [esp], dl
            dec esp
            xchg eax, edi
            cmp edi, 0
            jnz .loop4
            cmp eax, 0
            jnz .loop4
        mov [ebx], dword 0
        jmp .push_done

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
    .process_next:
        xor edx, edx
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
        cmp edx, 'i'
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
        mov dl, byte [ecx]
        cmp edx, 'l'
        jne .incorrect_sequence
        or eax, FLAG_LONG
        inc ecx
        jmp .process_format
    .print_int:
        add esp, 4           ; erase address of format sequence start, no need anymore
        push edi
        test eax, FLAG_LONG
        jnz .send_address
      .send_value:
        mov edi, [edi]
      .send_address:
        call itoa
        pop edi
        test eax, FLAG_LONG
        jz .add_4
        add edi, 4
      .add_4:
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
        or eax, FLAG_PLUS
        inc ecx
        jmp .process_format
    .minus:
        test eax, FLAGS_ENDED
        jnz .incorrect_sequence
        or eax, FLAG_ALIGN_LEFT
        inc ecx
        jmp .process_format
    .space:
        test eax, FLAGS_ENDED
        jnz .incorrect_sequence
        or eax, FLAG_SPACE
        inc ecx
        jmp .process_format
    .zero:
        test eax, FLAGS_ENDED
        jnz .digit
        or eax, FLAG_ZEROS
        inc ecx
        jmp .process_format
    .percent:
        test eax, FLAG_CTRL_SEQ
        jnz .incorrect_sequence   ; '%' in formatting sequence
        xor eax, eax
        xor esi, esi
        or eax, FLAG_CTRL_SEQ
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
        pop ebx
        pop edi
        pop esi
        pop ebp
        ret
