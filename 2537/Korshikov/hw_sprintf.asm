global hw_sprintf

section .text


    ;control flags
    
    ;control sequence flags

    ;always print sign
    %assign     FLAG_PRINT_SIGN                         00000001h

    ;print space if first symbol non-sign
    %assign     FLAG_PRINT_SPACE                        00000002h

    ;left allign if number width < minimal width
    %assign     FLAG_LEFT_ALLIGN                        00000004h

    ;fill with zeros if number width < minimal width 
    ;WARING ignore if set FLAG_LEFT_ALLIGN
    %assign     FLAG_FILL_ZEROS                         00000008h


    ;type size flags

    ;long long(64 bit)
    %assign     FLAG_LONG_LONG                          00000010h

    ;unsigned
    %assign     FLAG_UNSIGNED                           00000020h

    ;negative value
    %assign     FLAG_NEGATIVE                           00000040h


    ;void hw_sprintf(char *out, char const *format, ...);
    ;set out - string for format string with value of var
    ;
    ;
    ;@out - address for result string
    ;@format - format of result string
    ;@... values of varibels

    ;esi format string now position address
    ;edi out string now position address
    ;ebp varible address
    ;ebx flags
    ;edx current symbol
    ;ecx minimal number width
    hw_sprintf:
        push ebp
        push esi
        push edi
        push ebx

        mov edi, [esp + 20]                             ;set out address
        mov esi, [esp + 24]                             ;set format address
        lea ebp, [esp + 28]                             ;set varible address
        xor edx, edx                                    ;erase register for new symbol
    .process_next:
        mov dl, byte [esi]                              ;read symbol
        cmp edx, 0                                      ;end of string?
        je .format_string_end                
        cmp edx, '%'                                    ;start control sequence?
        je .percent
        mov [edi], edx                                  ;add symbol to out string
        inc edi                                         ;update out string now symbol address
        inc esi                                         ;update format string now symbol address
        jmp .process_next                               ;next iteration read symbol

    .percent
        xor ecx, ecx
        xor ebx, ebx
        inc esi                                         ;update format string now symbol address
        push esi                                        ;save start control sequence position 
        jmp .parse_control_sequence_flags               

    .parse_control_sequence_flags
        mov dl, byte [esi]                              ;read symbol
        cmp edx, '+'                                    ;set FLAG_PRINT_SIGN 
        je .set_FLAG_PRINT_SIGN
        cmp edx, ' '                                    ;set FLAG_PRINT_SPACE 
        je .set_FLAG_PRINT_SPACE
        cmp edx, '-'                                    ;set FLAG_LEFT_ALLIGN 
        je .set_FLAG_LEFT_ALLIGN
        cmp edx, '0'                                    ;set FLAG_FILL_ZEROS 
        je .set_FLAG_FILL_ZEROS

    .parse_control_sequence_minimal_width               ;parse number - minimal width
        mov eax, edx
        sub eax, '0'                                    
        cmp eax, 9                                      ;if 0<= symbol <=9 add syymbol to minimal width
        jbe .add_minimal_width

    .parse_control_sequence_size
        cmp edx, 'l'
        je .try_set_type_flag_FLAG_LONG_LONG

    .parse_control_sequence_type
        cmp edx, 'i'                                    ;set type dec 
        je .print_number
        cmp edx, 'd'                                    ;set type dec
        je .print_number
        cmp edx, 'u'                                    ;set type unsigned dec 
        je .unsigned_print_number
        cmp edx, '%'                                    ;set type % 
        je .print_procent


    .incorrect_control_sequence                     
        mov byte [edi], '%'                             ;add '%' to out string
        inc edi                                         ;update out string now symbol address
        pop esi                                         ;reset format string position to start incorrect control sequence
        jmp .process_next

    .add_minimal_width
        imul ecx, 10                                    
        add ecx, eax
        inc esi
        mov dl, byte [esi]
        jmp .parse_control_sequence_minimal_width

    .try_set_type_flag_FLAG_LONG_LONG
        inc esi
        mov dl, byte [esi]                              ;check that second symbol 'l'
        cmp edx, 'l'
        je .set_type_flag_FLAG_LONG_LONG
        jmp .incorrect_control_sequence

    .set_type_flag_FLAG_LONG_LONG
        or ebx, FLAG_LONG_LONG
        inc esi
        mov dl, byte [esi]
        jmp .parse_control_sequence_type 


    .set_FLAG_PRINT_SIGN
        or ebx, FLAG_PRINT_SIGN                         ;set FLAG_PRINT_SIGN
        inc esi                                         ;update format string now symbol address
        jmp .parse_control_sequence_flags               ;parse next control sequence flags

    .set_FLAG_PRINT_SPACE
        or ebx, FLAG_PRINT_SPACE                        ;set FLAG_PRINT_SPACE
        inc esi                                         ;update format string now symbol address
        jmp .parse_control_sequence_flags               ;parse next control sequence flags

    .set_FLAG_LEFT_ALLIGN
        or ebx, FLAG_LEFT_ALLIGN                        ;set FLAG_LEFT_ALLIGN
        inc esi                                         ;update format string now symbol address
        jmp .parse_control_sequence_flags               ;parse next control sequence flags

    .set_FLAG_FILL_ZEROS
        or ebx, FLAG_FILL_ZEROS                         ;set FLAG_FILL_ZEROS
        inc esi                                         ;update format string now symbol address
        jmp .parse_control_sequence_flags               ;parse next control sequence flags


    .for_test_process_next
        add esp, 4
        inc esi
        jmp .process_next


    .print_procent
        add esp, 4                                      ;remove pos start control sequence
        inc esi
        mov byte [edi], '%'                             ;add '%' to out string
        inc edi                                         ;update out string now symbol address
        jmp .process_next


    .format_string_end:
        mov [edi], byte 0                               ; end of string
        pop ebx
        pop edi
        pop esi
        pop ebp
        ret

    .unsigned_print_number
        or ebx, FLAG_UNSIGNED
        jmp .print_number

    .print_number
        add esp, 4                                      ;remove pos start control sequence
        inc esi
        test ebx,FLAG_LONG_LONG
        jnz .get_64

    .get_32
        xor edx,edx                                     
        mov eax,[ebp]                                   ;get value of var to eax
        add ebp,4                                       ;move ebt to next var

        test ebx,FLAG_UNSIGNED                          
        jnz .print_exist_var
        test eax, eax
        jge .print_exist_var
    ;eax is negative
        or ebx,FLAG_NEGATIVE
        neg eax                                         ;abs value
        jmp .print_exist_var

    .get_64
        mov eax, [ebp]                                  ;get low bits
        mov edx, [ebp+4]                                ;get hight bits
        add ebp,8

    
        test ebx,FLAG_UNSIGNED                          
        jnz .print_exist_var
        test edx, edx
        jge .print_exist_var
    ;64-bit number is negative
        or ebx,FLAG_NEGATIVE
        not eax                                         ;get 64 abs value
        not edx
        add eax, 1
        adc edx, 0


    .print_exist_var

        test ebx,FLAG_FILL_ZEROS
        jz .next_step
        test ebx,FLAG_LEFT_ALLIGN
        jz .next_step
        xor ebx, FLAG_FILL_ZEROS

    .next_step

        push esi
        push ebx
        push ebp
        mov ebp, 10
        mov ebx,esp
        mov esi, edx        

        ;division is based on http://www.df.lth.se/~john_e/gems/gem0033.html
    .output_hight:
        cmp edx, 10
        jb .output_lower

        mov esi, edx        
        xchg eax, esi       
        xor edx, edx        
        div ebp         
        xchg eax, esi   
        div ebp         

        add dl,'0'
        push edx
        dec ecx                                         ;add symbol to stack

        mov edx, esi        

        jmp .output_hight
    .output_lower:
        div ebp

        
        add dl,'0'
        push edx                                        ;add symbol to stack
        dec ecx

        xor edx, edx
        test eax, eax
        jnz .output_lower

        mov eax,ebx
        mov ebx, [eax+4]

    ;try print left space
        test ebx, FLAG_LEFT_ALLIGN
        jz .try_print_left_space

    .print_sign
        test ebx,FLAG_NEGATIVE
        jnz .print_minus


        test ebx,FLAG_PRINT_SIGN
        jnz .print_plus

        test ebx,FLAG_PRINT_SPACE
        jnz .print_space

    .t2_la
    ;try print left space
        test ebx, FLAG_LEFT_ALLIGN
        jz .try2_print_left_space


    .print_number_from_stack

    ;try print left zeros
        test ebx, FLAG_FILL_ZEROS
        jnz .try_print_left_zero

    .loop1
        cmp eax,esp
        je .print_right_space
        pop edx
        mov [edi], edx                                  ;add symbol to out string
        inc edi                                         ;update out string now symbol address
        jmp .loop1

    

    ;try print right space
    .print_right_space 
        cmp ecx, 0
        jle .pre_process_next
        mov byte [edi], ' '                             ;add ' ' to out string
        inc edi                                         ;update out string now symbol address
        dec ecx
        jmp .print_right_space

    .pre_process_next
        pop ebp
        pop ebx
        pop esi
        jmp .process_next

    .print_minus
        mov byte [edi], '-'                             ;add '-' to out string
        dec ecx
        inc edi                                         ;update out string now symbol address
        jmp .print_number_from_stack

    .print_plus
        mov byte [edi], '+'                             ;add '+' to out string
        dec ecx
        inc edi                                         ;update out string now symbol address
        jmp .print_number_from_stack

    .print_space
        mov byte [edi], ' '                             ;add ' ' to out string
        dec ecx
        inc edi                                         ;update out string now symbol address
        jmp .print_number_from_stack

    .try_print_left_space                               ;try print all left space except one
        test ebx,FLAG_FILL_ZEROS
        jnz .print_sign
        cmp ecx, 1
        jg .print_left_space
        jmp .print_sign

    .print_left_space
        cmp ecx, 1
        je .print_sign
        mov byte [edi], ' '                             ;add ' ' to out string
        inc edi                                         ;update out string now symbol address
        dec ecx
        jmp .print_left_space
        

    .try2_print_left_space                              ;the latter left space
        test ebx,FLAG_FILL_ZEROS
        jnz .try_print_left_zero
        cmp ecx, 0
        jg .print2_left_space
        jmp .print_number_from_stack

    .print2_left_space
        mov byte [edi], ' '                             ;add ' ' to out string
        inc edi                                         ;update out string now symbol address
        dec ecx
        je .print_number_from_stack
        


    .try_print_left_zero                              ;try print left zeros
        cmp ecx, 0
        jg .print_left_zero
        jmp .loop1

    .print_left_zero 
        cmp ecx, 0
        je .loop1
        mov byte [edi], '0'                             ;add '0' to out string
        inc edi                                         ;update out string now symbol address
        dec ecx
        jmp .print_left_zero
        