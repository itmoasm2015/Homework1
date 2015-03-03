global hw_sprintf

extern printf
extern scanf

section .text

;flags for hw_itoa
FLAG_SIGN_BIT      equ 1<<0
TYPE_BIT           equ 1<<1
SIZE_BIT           equ 1<<2

SIGN_BIT equ 1<<31;sign bit

;flags for format flags, for size of number, for signed or unsigned
;also RES_SUCCESS_BIT will set up if format string was succesfuly parsed
;RES_NOT_FULL_BIT will set up if format string ends not correct format, for example %ll, %u, %+0, %l etc.
RES_FLAG_PLUS_BIT  equ 1<<0
RES_TYPE_BIT       equ 1<<1
RES_SIZE_BIT       equ 1<<2
RES_FLAG_ZERO_BIT  equ 1<<3
RES_FLAG_MIN_BIT   equ 1<<4
RES_FLAG_SPACE_BIT equ 1<<5
RES_NOT_FULL_BIT   equ 1<<6
RES_SUCCESS_BIT    equ 1<<7

;ebx - buffer
;eax - format
hw_sprintf:
    ;store registers
    push ebp
    mov ebp, esp
    push ebx
    push eax
    push edi
    push edx
    push ecx
    push esi

    mov ebx, [ebp + 8];set buffer ptr
    mov eax, [ebp + 12];set format ptr
    add ebp, 16;ebp pointed on first argument

    .loop
        cmp byte [eax], 0 ;if end of line - break
        je .break
        
        cmp byte [eax], '%'
        jne .write_symbol
            ;if %format
            push eax;save eax
            inc eax
            call parse;try parse format
            ;after call parse 
                ;esi - value of width
                ;dl - mask format flags, size of number and signed/unsigned
            test dl, RES_SUCCESS_BIT
            jnz .succ_parsed
                ;if not succes
                pop eax;restore eax
                test dl, RES_NOT_FULL_BIT
                jnz .break

                ;if incorrect format
                cmp byte [eax + 1], '%'
                jne .write_symbol;if not %% - write usual symbol
                inc eax
                jmp .write_symbol;if %% - write %
            .succ_parsed
                ;if format was succesful parsed
                add esp, 4;pop eax - old value isn't valid
                mov di, dx;set flags for call hw_itoa
                and di, RES_FLAG_PLUS_BIT | RES_TYPE_BIT | RES_SIZE_BIT ;get flags for hw_itoa
                push eax;store eax
                push edx;store ebx
                push numBuff;buffer for hw_itoa
                test di, RES_SIZE_BIT ;determine size of number
                jz .is32bit
                    ;if 64 bit, load in edx
                    mov eax, [ebp];if 64bit load in [edx:eax] our number
                    add ebp, 4
                    mov edx, [ebp]
                    add ebp, 4
                    jmp .load_number_done
                .is32bit
                    ;if 32 bit, load in eax our number
                    mov eax, [ebp]
                    add ebp, 4
                .load_number_done
                call hw_itoa;call itoa
                ;after call hw_itoa
                    ;ecx - length of number without sign
                    ;numBuff[0] contains sign or 0, if sign doesn't requere
                    ;numBuff[1..ecx] contains reverse number
                add esp, 4 ;pop buffer, restore edx, eax
                pop edx
                pop eax

                test dl, RES_FLAG_SPACE_BIT
                jz .not_space
                    ;if space flag was set up
                    cmp byte [numBuff], 0
                    jne .not_space;if not sign, set ' ' instead of sign
                    mov byte [numBuff], ' '
                .not_space

                cmp byte [numBuff], 0 
                je .not_sign
                inc ecx ;if first byte not null - inc length of number
                .not_sign

                cmp ecx, esi;compare length of number with width
                jb .length_of_number_less_width
                    ;if length of number atleast width - write number in buffer
                    mov dl, [numBuff];write_sign requere dl - sign
                    call write_sign
                    call write_digits;write_digits take digits from numBuff
                    jmp .next_iter_loop

                .length_of_number_less_width

                test dl, RES_FLAG_MIN_BIT
                jz .no_left_align_flag
                    ;if was set up flag minus - left align
                    mov dl, [numBuff];write_sign requere dl - sign
                    call write_sign
                    call write_digits;write digits take digits from numBuff
                    mov dl, ' ';write_char requere dl - char for writing
                    call write_char
                    jmp .next_iter_loop
                .no_left_align_flag

                test dl, RES_FLAG_ZERO_BIT
                jz .no_zero_flag
                    ;if set up zero flag
                    mov dl, [numBuff];write_sign requere dl - sign
                    call write_sign
                    mov dl, '0';write_char requere dl - char for writing
                    call write_char
                    call write_digits;write_digits take digits from numBuff
                    jmp .next_iter_loop
                .no_zero_flag

                mov dl, ' ';write_char requere dl - char for writing
                call write_char
                mov dl, [numBuff]
                call write_sign;write_sign requere dl - sign
                call write_digits;write_digits take digits from numBuff
                jmp .next_iter_loop
        .write_symbol
        ;write usual symbol
        mov cl, [eax]
        mov [ebx], cl
        inc ebx
        inc eax

        .next_iter_loop
        jmp .loop
    .break
    mov byte [ebx], 0;set terminated byte

    ;restore registers
    pop esi
    pop ecx
    pop edx
    pop edi
    pop eax
    pop ebx
    pop ebp
    ret

;requered 
    ;dl - sign of number or 0 if no sign
    ;ecx - length of number inclusive sign
    ;esi - width
    ;ebx - ptr on out buffer
write_sign:
    cmp dl, 0
    je .no_sign;if sign
        mov [ebx], dl;write sign
        inc ebx
        dec esi
        dec ecx
    .no_sign
    ret

;requered 
    ;dl - char
    ;ecx - length of number inclusive sign
    ;esi - width
    ;ebx - ptr on out buffer
write_char:
    .write_char_loop
        mov [ebx], dl;write char
        inc ebx
        dec esi
        cmp esi, ecx;if width equal length of number - break
        jne .write_char_loop
    ret

;requered
    ;digits of number in numBuff in reverse order
    ;ebx - ptr on out buffer
    ;esi - width
write_digits:
    push edx;store edx
    .write_digits_loop
        mov dl, [numBuff + ecx]
        mov [ebx], dl
        inc ebx
        dec esi
        loop .write_digits_loop;while length of number isn't zero
    pop edx;restore edx
    ret

;function for parsing of format string
;requered
    ;eax - start position of format string
;returned
    ;dl - mask contains  format flags, size of number and signed/unsigned
    ;esi - width
parse:
    ;store registers
    push ebx

    mov dl, 0;set up zero to mask
    .get_flags_loop;loop for parsing format flags
        cmp byte [eax], 0
        je .not_full_format;if end of line - format doesn't completed, like %0, %+-, %0+-, % 0 etc.

        cmp byte [eax], '+'
        jne .not_plus
            ;if plus flag set up bit to mask
            or dl, RES_FLAG_PLUS_BIT
            jmp .next_iteration
        .not_plus

        cmp byte [eax], '-'
        jne .not_minus
            ;if minus flag set up bit to mask
            or dl, RES_FLAG_MIN_BIT
            jmp .next_iteration
        .not_minus

        cmp byte [eax], '0'
        jne .not_zero
            ;if zero flag set up bit to mask
            or dl, RES_FLAG_ZERO_BIT
            jmp .next_iteration
        .not_zero

        cmp byte [eax], 32
        jne .break_flags_loop
            ;if space flag set up bit to mask
            or dl, RES_FLAG_SPACE_BIT
            jmp .next_iteration

        .next_iteration
        inc eax;next char
        jmp .get_flags_loop
    .break_flags_loop

    xor esi, esi
    .get_width_loop;calculate width value
        cmp byte [eax], 0 ;if end of line - format doesn't completed, like %020, %+-4, %0+-15, % 05 etc.
        je .not_full_format

        ;check, that [eax] is digit
        cmp byte [eax], '0'
        jb .break_get_width_loop
        cmp byte [eax], '9'
        ja .break_get_width_loop

        ;if [eax] is digit store registers and mul esi on 10
        push edx
        push eax
        mov ebx, 10
        mov eax, esi
        mul ebx
        mov esi, eax
        pop eax
        pop edx
        
        ;get next digit and add to esi
        xor ebx, ebx
        mov bl, [eax];store to bl next digit 
        sub bl, '0'
        add esi, ebx

        inc eax;next char
        jmp .get_width_loop
    .break_get_width_loop

    cmp byte [eax], 'l';parse ll
    jne .get_type;if [eax] not equal 'l' - get type of number %d, %i or %u
    inc eax
    cmp byte [eax], 0 ;if end of line - format doesn't complete, like %020l, %+-4l, %0+-15l, % 05l, %l etc.
    je .not_full_format
    cmp byte [eax], 'l'
    jne .cant_parse;if incorrect specificator
    or dl, RES_SIZE_BIT;if format string contain ll - set up bit to mask
    inc eax;next char

    .get_type
    ;if %u - set up 1 to mask
        ;1 - %u
        ;0 - %d or %i
    cmp byte [eax], 0 ;if end of line - format doesn't complete
    je .not_full_format
    cmp byte [eax], 'u'
    jne .eq_d
        ;if %u - set up 1 bit in mask
        or dl, RES_TYPE_BIT
        jmp .success_parsed

    .eq_d
        ;if %d - set up 0 bit in mask
        cmp byte [eax], 'd'
        je .success_parsed

    .eq_i
        ;if %i - set up 0 bit in mask
        cmp byte [eax], 'i'
        je .success_parsed

    jmp .cant_parse;if can't parse type 

    .not_full_format
    or dl, RES_NOT_FULL_BIT;if string format doesn't complete - set up bit
    jmp .exit

    .cant_parse;if cant parse - exit
    jmp .exit

    .success_parsed
    inc eax
    or dl, RES_SUCCESS_BIT;if success parsed - set up bit

    .exit
    pop ebx;restore ebx
    ret

;function for convert number to string
;requered
    ;edx:eax - number
    ;di - flags
        ;0 bit - sign flag from format string
        ;1 bit - unsigned or signed, if equal 1 - unsigned, signed otherwise 
        ;2 bit - long long or int, if equal 1 - long long, int - otherwise
    ;ebx - ptr on buffer
;returned
    ;ecx - length of array exclusive sign
    ;buffer from ebx contains number in next format: sign, d[n],d[n-1], ... d[1], 
    ;to t.a [ebx] - sign of number or 0 if sign doesn't requere and number in reverse order
hw_itoa:
    ;store registers
    push ebp
    mov ebp, esp
    push ebx
    push edx
    push eax
    push edi
    push esi

    mov ebx, [ebp + 8];get ptr on out buffer

    mov byte [ebx], 0 ;set zero in sign char

    test di, SIZE_BIT
    jnz .is64bit_number
    ;if 32bit number set edx 0
    xor edx, edx
    .is64bit_number

    test di, TYPE_BIT
    jz .not_unsigned
        ;if number is unsigned
        jmp .check_flag_sign
    .not_unsigned
    ;if signed

    test di, SIZE_BIT
    jnz .is_long
        ;part for 32bit number, set edx -1 111...11b if number is negative for simulation 32bit number like 64bit number
        test eax, SIGN_BIT
        jz .eax_positive
        mov edx, -1;if negative 32bit number, then set up 1111..1b
        .eax_positive
    .is_long
    ;after this line - 32 bit number represent like 64 bit number

    test edx, SIGN_BIT
    jnz .minus_sign;if number is negative
    jmp  .check_flag_sign;else

    .minus_sign
        ;if number is negative - get absolute value and write sign
        mov byte [ebx], '-';write sign
        ;this part get absolute value of number
        not edx
        not eax
        add eax, 1
        adc edx, 0
        ;after this line - [edx:eax]  positive number
        jmp .sign_done;operations with sign completed

    .check_flag_sign
        test di, FLAG_SIGN_BIT
        jz .sign_done
        ;if flag + was set up
        mov byte [ebx], '+'
        jmp .sign_done

    .sign_done

    mov ecx, 1;initializate index for output buffer
    mov esi, 10;for division on 10

    ;this loop convert a = [edx:eax] to number
    .loop
        mov edi, eax;edi - storage of eax

        ;this part div [0:edx] on 10
        ;in eax - a / b
        ;in edx - a % b
        ;division made like long division
            ;edx:eax|10
            ;.......|-------------
            ;remain |newEdx:newEax
        xchg edx, eax
        mov edx, 0
        div esi
        xchg edi, eax
        div esi

        add edx, '0';store digit
        mov [ebx + ecx], edx
        inc ecx

        mov edx, edi;new number [newEdx: newEax]
        or edi, eax;if edx = 0 and eax = 0 - then break
        cmp edi, 0
        jnz .loop;while number doesn't equal 0

    .all_done

    mov byte [ebx + ecx], 0 ;write terminated char
    dec ecx ;set correct length of number
    
    ;restore registers
    pop esi
    pop edi
    pop eax
    pop edx
    pop ebx
    pop ebp
    ret

section .bss
    numBuff: resb 25
