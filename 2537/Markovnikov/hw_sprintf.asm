global hw_sprintf
section .bss
        out_str:	resd 1
        temp:		resd 1
        tmp:  		resd 1
section .text

ZERO_FLAG   equ 1 << 0  ; is used for showing zeroes
PLUS_FLAG   equ 1 << 1  ; is used for showing plus sign
MINUS_FLAG  equ 1 << 2  ; is used for showing minus sign
SPACE_FLAG  equ 1 << 3  ; is used for printing spaces
LONG_FLAG   equ 1 << 4  ; means that number is 64-bit type
WIDTH_FLAG  equ 1 << 5  ; is used for setting width of the number
SIGN_FLAG   equ 1 << 6  ; shows that number is negative

section .data
    CONST10:     dd    10

%define testflag(f) test ch, f
%define setflag(f) or ch, f
%define setchar(c) mov cl, c
%define compchar(c) cmp cl, c
%define DEG 2147483648

%macro setfl 0
        setchar('+')
        test eax, DEG
        jz .test_long_s  
        testflag(SIGN_FLAG)
        jz .test_long_s
        setchar('-')
        testflag(LONG_FLAG)
        jz .num_32
    .num_64:
        not eax
        not edx
        add edx, 1
        adc eax, 0
        jmp .test_long_s
    .num_32:        
        neg eax         ; take abs
%endmacro

; macro for setting flag

%macro sfl 1            
     setflag(%1)
     jmp .start_parse_percent
%endmacro

%macro f_take_digits 0
     .take_digits:           ; take digit by digit
        mov ebx, eax
        mov eax, edx
        xor edx, edx
        div ecx
        xchg eax, ebx
        div ecx 
        add dl, '0'
        mov byte [esi], dl
        dec esi
        mov edx, ebx
        cmp edx, 0
        jne .take_digits
        cmp eax, 0
        je  .zero_or_space
    %endmacro

    ; help_function to know a size of the string 
    ; ebx - size of the number
    ; other arguments like in print_num function
    find_digits:
        setfl          ; set all flags that are possible
    .test_long_s:
        testflag(LONG_FLAG)
        jz .change_sign_s 
        xchg eax, edx
    .change_sign_s:
        testflag(SPACE_FLAG + PLUS_FLAG)
        jnz .get_next_s
        compchar('-')
        je .get_next_s
        jmp .skip_s
    .get_next_s:
        inc ebx
    .skip_s:
        mov ecx, 10     ; for div 10
        mov esi, ebx
    .take_digits:       
        mov ebx, eax
        mov eax, edx
        xor edx, edx
        div ecx
        xchg eax, ebx    
        div ecx 
        mov edx, ebx
        inc esi
        cmp eax, 0
        je  .break_s
        jmp .take_digits
    .break_s:
        mov eax, esi 
        ret
        
    ; void hw_sprintf(char *out, char const *format, ...)
    ; arguments:
    ;	out_str - out
	;	esi - format
	;	ebx - first argument
    hw_sprintf:
        push ebx
        push esi
        push edi
        xor ebx, ebx    
        mov edx, [esp + 20] ; format
        mov eax, [esp + 16] ; pointer to out
        mov esi, esp
        add esi, 24         ; first argument
    .loop_for_percent:      ; parse percent
        setchar(byte [edx])
        compchar('%')       ; if percent
        jne .to_the_end
        push edx
        xor ch, ch          ; set no flag
        inc edx 
    .parse_percent:
        setchar(byte [edx])
        testflag(LONG_FLAG)
        jnz .compare_with_l ; read other flags
        testflag(WIDTH_FLAG)
        jnz .compare_with_l ; parse after ll
        compchar('0')
        je .set_zero_fl     ; set flags
        compchar('+')
        je .set_plus_fl
        compchar('-')
        je .set_minus_fl
        compchar(' ')
        je .set_space_fl
        compchar('1')
        jl .compare_with_l
        compchar('9')
        jle .push_size
    .compare_with_l:        ; if it's long
        compchar('l')
        je .if_found_l
    .compare_digit_flags:   ; parse flags for digits like %, u, d, i
        compchar('%')
        je .parse_percent_again
        compchar('u')
        je .unset_SIGN_FLAG_func
        compchar('d')       ; if need sign
        je .set_SIGN_FLAG_func
        compchar('i')
        je .set_SIGN_FLAG_func
    .format_err:            ; skip and pop previous position
        pop edx
        mov byte [eax], '%'
        inc edx
        inc eax
        jmp .loop_for_percent
    .push_size:             ; parse size flag
        xor ebx, ebx        ; refresh size to zero
        push eax
    .until_end_of_line:     ; 
        setchar(byte [edx])
        compchar('0')       ; >= 0
        jl .comp_l_in_loop
        compchar('9')       ; <= 9
        jg .comp_l_in_loop
        inc edx             ; take next
        push edx
        push ecx        
        mov eax, ebx
        mov ecx, 10         ; *10
        mul ecx
        pop ecx
        push ecx
        sub cl, '0'         ; take digit
        and ecx, 255        ; only last two bits
        mov ebx, eax
        add ebx, ecx                                          
        pop ecx
        pop edx
        jmp .until_end_of_line
    .comp_l_in_loop:        ; start to set flags
        pop eax    
        setflag(WIDTH_FLAG)
        jmp .parse_percent
    .set_zero_fl:
        sfl ZERO_FLAG
    .set_plus_fl:
        sfl PLUS_FLAG
    .set_minus_fl:
        sfl MINUS_FLAG
    .set_space_fl:
        sfl SPACE_FLAG
    .if_found_l:            ; read l
        inc edx 
        setchar(byte [edx])
        compchar('l')       ; if read l again it's ok
        jne .format_err
        sfl LONG_FLAG       ; set long flag
    .start_parse_percent:   
        inc edx             ; take next
        jmp .parse_percent  ; repeat to parse percent
    .set_SIGN_FLAG_func: 
        setflag(SIGN_FLAG)
    .unset_SIGN_FLAG_func:
        push edx
        push esi
        push ecx
        push eax
        testflag(LONG_FLAG)
        jz .short_number
    .long_long_number:
        push dword [esi + 4]
        push dword [esi]
        jmp .call_size_func ; so we need to know a size of the number    
    .short_number:
        push dword 0
        push dword [esi]
    .call_size_func:        ; size in ebx now
        call size_num
        add esp, 8
        mov edi, eax
        pop eax
        pop ecx
        push ecx
        push edi
        push ebx
        testflag(LONG_FLAG)
        jz .for_short       ; if not long number
    .for_long_long:
        push dword [esi + 4]
        push dword [esi]
        jmp .write_and_test_long_fl
    .for_short:
        push dword 0        ; it's high half of the number
        push dword [esi]
    .write_and_test_long_fl:
        call write_result   ; write to the answer and take next args
        add esp, 16
        pop ecx
        pop esi
        pop edx
        add esi, 4          ; take next
        testflag(LONG_FLAG)
        jz .skip_long_fl
        add esi, 4
    .skip_long_fl:
        jmp .if_no_percent_again 
    .parse_percent_again:
        mov byte [eax], '%'
        inc eax
        jmp .if_no_percent_again 
    .if_no_percent_again:
        add esp, 4
        inc edx
        jmp .loop_for_percent
    .to_the_end:
        mov byte [eax], cl
        inc edx             ; take next
        inc eax
        compchar(0)         ; if the end of the line
        jne .loop_for_percent  
        pop edi
        pop esi
        pop ebx 
        ret
        
    ; takes number in 64-bit format
    ; returns count of chars that we need for casting our number to a string
    size_num:
        push ebx
        push esi
        xor ebx, ebx
        mov eax, dword [esp + 12]
        mov edx, dword [esp + 16]
        testflag(LONG_FLAG)
        jz .set_sign_s
        xchg eax, edx
    .set_sign_s:
        call find_digits
        pop esi
        pop ebx 
        ret
        
    ; prints number of fixed length      
    ; Takes:
    ;           eax - number
    ;           ebx - width
    ; Returns:  esi - output string 
    write_result:
        push ebx
        push eax
        mov esi, eax            ; pointer to out
        mov edi, eax
        mov eax, dword [esp + 12]   ; high half
        mov edx, dword [esp + 16]   ; low half
        mov ebx, dword [esp + 20]
        cmp ebx, dword [esp + 24]
        jge .test_long_flag
        mov ebx, dword [esp + 24]
    .test_long_flag:
        testflag(LONG_FLAG)
        jz .set_sign_s
        xchg eax, edx
    .set_sign_s:
        setfl
    .test_long_s:
        testflag(LONG_FLAG)
        jz .test_minus_flag 
        xchg eax, edx
    .test_minus_flag:
        push ecx
        testflag(MINUS_FLAG)
        jz .write_minus_char_case
        push esi
        mov esi, esi
        add esi, ebx
        sub esi, 1
    .wtite_space_char:              ; write spaces
        mov byte [esi], ' '
        dec esi
        cmp esi, edi
        jge .wtite_space_char
        pop esi
        add esi, dword [esp + 28]
        dec esi
        jmp .no_write_minus
    .write_minus_char_case:
        mov esi, esi
        add esi, ebx
        sub esi, 1
    .no_write_minus:
        mov ecx, 10                 ; for div 10
        push ebx
        f_take_digits
    .add_some_zeroes:              ; add zeroes before number
        xor edx, edx
        div ecx
        add dl, '0'                ; print zero
        mov byte [esi], dl
        dec esi
        cmp eax, 0
        jnz .add_some_zeroes    
    .zero_or_space:
        pop ebx
        pop ecx
        testflag(ZERO_FLAG)
        push ecx
        mov ah, ' '
        jz .test_sign_flags
        mov ah, '0'
    .test_sign_flags:
        pop ecx
        testflag(ZERO_FLAG)
        push ecx
        jnz .skip_setting
        pop ecx
        testflag(PLUS_FLAG)
        push ecx
        jnz .set_sign
        compchar('-')
        je .set_sign
        jmp .skip_setting
    .set_sign:
        mov byte [esi], cl
        dec esi
    .skip_setting:
        cmp esi, edi
        jl .return_res
    .loop0:
        mov byte [esi], ah
        dec esi
        cmp esi, edi
        jge .loop0
        pop ecx
        testflag(ZERO_FLAG)
        push ecx
        jz .return_res
        pop ecx
        testflag(SPACE_FLAG)   
        push ecx
        jz .if_not_space
        inc esi
        mov byte [esi], ' '
        dec esi
    .if_not_space:
        pop ecx
        testflag(PLUS_FLAG)
        push ecx
        jnz .set_sign_after
        compchar('-')
        je .set_sign_after
        jmp .return_res
        .set_sign_after:
        inc esi
        mov byte [esi], cl
        dec esi
    .return_res:
        pop ecx      
        pop eax
        add eax, ebx
        pop ebx
        ret
