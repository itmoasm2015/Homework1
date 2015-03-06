global _hw_sprintf

extern _printf

%define FLAG_ZERO  1
%define FLAG_PLUS  2
%define FLAG_MINUS 4
%define FLAG_SPACE 8
%define FLAG_LONG  16
%define FLAG_WIDTH 32
%define FLAG_SIGN  64

section .data
    width: dd 0

section .text

    count_unsigned_length:
    
    push ebx
    
    ; ----- safe edx zone ----- ;
    
    xor ebx, ebx
    mov eax, dword [esp + 8]
    mov edx, dword [esp + 12]

    test ch, FLAG_LONG
    jz .after_swap 
    xchg eax, edx
    .after_swap:
    
    mov cl, '+'
    test eax, 0x80000000 ; 100...0b 
    jz .after_change_sign 
    test ch, FLAG_SIGN
    jz .after_change_sign
    mov cl, '-' 
    
    test ch, FLAG_LONG
    jz .32bit_complement
    .64_complement:
    not eax
    not edx
    add edx, 1
    adc eax, 0
    jmp .after_change_sign
    .32bit_complement:        
    not eax ; from two's complement 
    inc eax ; to absolute value
    .after_change_sign:
       
    test ch, FLAG_LONG
    jz .after_swap1 
    xchg eax, edx
    .after_swap1:

    test ch, FLAG_PLUS + FLAG_SPACE
    jnz .to_inc
    cmp cl, '-'
    je .to_inc
    jmp .after_inc
    .to_inc:
    inc ebx ; result + 1 if sign '+' prints
    .after_inc:
    mov ecx, 10 ; div 10 
    
    push esi
    mov esi, ebx
     
    .loop:
    ; divide long number edx:eax by ecx:
    ; 0:edx / ecx = quot1: eax, rem1: edx
    ; rem1:eax / ecx = quot2: eax, rem2: edx
    ; summary, edx:eax /div/ ecx = quot1:quot2
    ;          edx:eax /mod/ ecx = rem2
    mov ebx, eax
    mov eax, edx
    xor edx, edx
    div ecx
    xchg eax, ebx    
    div ecx 
    mov edx, ebx
    inc esi
    cmp eax, 0
    jne .loop
    cmp edx, 0
    jne .loop
    mov eax, esi
    
    ;.loop:
    ;xor edx, edx
    ;div ecx
    ;inc ebx
    ;cmp eax, 0
    ;jne .loop
    ;mov eax, ebx
    
    
    
    pop esi
    pop ebx
    
    ret

    ; print_unsigned(number, width, number_width)
    print_unsigned:
    push ebx
    push eax
    mov esi, eax ; char* out
    mov edi, eax ; save initial char* out
    mov eax, dword [esp + 12]
    mov edx, dword [esp + 16]    
    ; ebx = max(width, number_width)
    mov ebx, dword [esp + 20]
    cmp ebx, dword [esp + 24]
    jge .continue
    mov ebx, dword [esp + 24]
    .continue:
    mov cl, '+'
    
    test ch, FLAG_LONG
    jz .after_swap 
    xchg eax, edx
    .after_swap:
    
    test eax, 0x80000000 ; 100....0b 
    jz .after_change_sign 
    test ch, FLAG_SIGN
    jz .after_change_sign
    mov cl, '-'
    
    test ch, FLAG_LONG
    jz .32bit_complement
    .64_complement:
    
    not eax
    not edx        
    add edx, 1
    adc eax, 0
    
    jmp .after_change_sign
    .32bit_complement:        
    not eax ; from two's complement 
    inc eax ; to absolute value
    .after_change_sign:
    
    test ch, FLAG_LONG
    jz .after_swap2 
    xchg eax, edx
    .after_swap2:
    
    push ecx
    test ch, FLAG_MINUS
    jz .else_minus
    
    push esi
    lea esi, [esi + ebx - 1]
    .fill_space:
    mov byte [esi], ' '
    dec esi
    cmp esi, edi
    jge .fill_space
    pop esi
    
    add esi, dword [esp + 28]
    dec esi
    jmp .after_minus
    .else_minus:
    lea esi, [esi + ebx - 1]
    .after_minus:
    mov ecx, 10 ; div 10 
    
    push ebx
    
    .loop:

    ; divide long number edx:eax by ecx:
    ; 0:edx / ecx = quot1: eax, rem1: edx
    ; rem1:eax / ecx = quot2: eax, rem2: edx
    ; summary, edx:eax /div/ ecx = quot1:quot2
    ;          edx:eax /mod/ ecx = rem2
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
    cmp eax, 0
    jne .loop
    cmp edx, 0
    jne .loop
    
    pop ebx

    pop ecx
    test ch, FLAG_ZERO
    push ecx
    mov ah, ' '
    jz .after_change_fill
    mov ah, '0'
  
    .after_change_fill:
    pop ecx
    test ch, FLAG_ZERO
    push ecx
    jnz .after_sign ; skip sign if zeroes

    pop ecx
    test ch, FLAG_PLUS
    push ecx
    jnz .set_sign
    cmp cl, '-'
    je .set_sign
    jmp .after_sign
    .set_sign:
    mov byte [esi], cl
    dec esi

    .after_sign:
    cmp esi, edi
    jl .after_loop
    .rest_loop:
    mov byte [esi], ah
    dec esi
    cmp esi, edi
    jge .rest_loop
    
    pop ecx
    test ch, FLAG_ZERO
    push ecx
    jz .after_loop ; skip sign if not zeroes
     
    pop ecx   
    test ch, FLAG_SPACE
    push ecx
    jz .after_space
    inc esi
    mov byte [esi], ' '
    dec esi
    
    .after_space:
    
    pop ecx
    test ch, FLAG_PLUS
    push ecx
    jnz .set_sign_after
    cmp cl, '-'
    je .set_sign_after
    jmp .after_loop
    .set_sign_after:
    inc esi
    mov byte [esi], cl
    dec esi

    .after_loop:
    pop ecx
    pop eax
    add eax, ebx
    pop ebx
    ret

    ; main function, strcpy now
    ; hw_sprintf(char* out, const char* format, ...) 
    _hw_sprintf:

    mov dword [width], 0

    ; all registers: eax, ebx, ecx, edx, esi, edi
    ; cdecl declare callee need to save ebx, esi, edi
    push ebx
    push esi
    push edi
    
    mov eax, [esp + 16] ; char* out
    mov edx, [esp + 20] ; const char* format
    lea esi, [esp + 24] ; place of 1st vararg

    .main_loop:
    mov cl, byte [edx]
    cmp cl, '%'
    jne .not_a_percent
    push edx    ; save start position of current format token
    xor ch, ch  ; state of reading format token, initially 0, no flags
    inc edx 
    
    ; case cl of '0', '+', '-', ' ', 'l', 'u', 'd', 'i', '%', '1'..'9'
    .parse_percent:
    mov cl, byte [edx]
    
    test ch, FLAG_WIDTH
    jnz .after_width
    
    cmp cl, '0'
    je .zero_flag
    cmp cl, '+'
    je .plus_flag
    cmp cl, '-'
    je .minus_flag
    cmp cl, ' '
    je .space_flag
    
    cmp cl, '1'
    jl .after_width
    cmp cl, '9'
    jle .read_width
    
    .after_width:
    cmp cl, '%'
    je .second_percent
    cmp cl, 'l'
    je .first_l
    cmp cl, 'u'
    je .unsigned
    cmp cl, 'd'
    je .signed
    cmp cl, 'i'
    je .signed
    
    .incorrect_format:
    pop edx ; restore position before 
    mov byte [eax], '%'
    inc edx
    inc eax
    jmp .main_loop
  
    .read_width:
    mov dword [width], 0
    .width_loop: 
        mov cl, byte [edx]
        cmp cl, '0'
        jl .after_width_loop
        cmp cl, '9'
        jg .after_width_loop
        inc edx

        push eax
        push edx
        push ecx
        
        xor edx, edx
        mov eax, dword [width]
        mov ecx, 10
        mul ecx
        
        pop ecx
        push ecx
        sub cl, '0'
        mov edx, ecx
        and edx, 0x000000FF
        add eax, edx
                
        mov dword [width], eax   
                                                                        
        pop ecx
        pop edx
        pop eax
        jmp .width_loop
    .after_width_loop:
    or ch, FLAG_WIDTH
    jmp .parse_percent
        
    .zero_flag:
    or ch, FLAG_ZERO
    jmp .after_symbol
    
    .plus_flag:
    or ch, FLAG_PLUS
    jmp .after_symbol
    
    .minus_flag:
    or ch, FLAG_MINUS
    jmp .after_symbol
    
    .space_flag:
    or ch, FLAG_SPACE
    jmp .after_symbol
    
    .first_l:
    inc edx
    mov cl, byte [edx]
    cmp cl, 'l'
    jne .incorrect_format
    or ch, FLAG_LONG
    jmp .after_symbol
    
    .after_symbol:
    inc edx
    jmp .parse_percent

    .signed: 
    or ch, FLAG_SIGN
    .unsigned:
    push edx
    push esi
    push ecx
    push eax
    ; call count_unsigned_length
    test ch, FLAG_LONG
    jz .32bit_l
    .64bit_l:
    push dword [esi + 4]
    push dword [esi]
    jmp .after_bit_l    
    .32bit_l:
    push dword 0     ; high half of number is 0
    push dword [esi] ; number 
    .after_bit_l:
    call count_unsigned_length 
    add esp, 8
    mov edi, eax ; return value of count_unsigned_length
    pop eax      ; restore eax value
    pop ecx
    push ecx
    ; call print_unsigned
    ; print(number, width, number_width)
    ; fourth argument passed as eax /fastcall/
    push edi         ; number_width
    push dword [width] ; width
    test ch, FLAG_LONG
    jz .32bit
    .64bit:
    push dword [esi + 4]
    push dword [esi]
    jmp .after_bit    
    .32bit:
    push dword 0     ; high half of number is 0
    push dword [esi] ; number 
    .after_bit:
    call print_unsigned
    add esp, 16
    ; eax is like a return value, it should be equal to it's value after [print_unsigned] call
    pop ecx
    pop esi
    pop edx
    add esi, 4 ; go to next vararg
    test ch, FLAG_LONG
    jz .after_64inc
    add esi, 4 ; another +4, total +8 -- go to next vararg after 64 bit value
    .after_64inc:
    jmp .after_terminal
      
    .second_percent:
    mov byte [eax], '%'
    inc eax
    jmp .after_terminal 
   
    .after_terminal: ; after d, u, and %
    add esp, 4
    inc edx
    jmp .main_loop
    

    .not_a_percent:
    mov byte [eax], cl
    inc edx
    inc eax
    cmp cl, 0
    jne .main_loop  
   
    ; restore ebx, esi, ebx
    pop edi
    pop esi
    pop ebx 
        
    ret