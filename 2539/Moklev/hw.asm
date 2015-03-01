global hw_sprintf

%define FLAG_ZERO  1
%define FLAG_PLUS  2
%define FLAG_MINUS 4
%define FLAG_SPACE 8
%define FLAG_LONG 16

section .text

    count_unsigned_length:
    
    push ebx
    
    xor ebx, ebx
    mov eax, dword [esp + 8]
    test ch, FLAG_PLUS + FLAG_SPACE
    jz .after_inc
    inc ebx ; result + 1 if sign '+' prints
    .after_inc:
    mov ecx, 10 ; div 10 
    .loop:
    xor edx, edx
    div ecx
    inc ebx
    cmp eax, 0
    jne .loop
    mov eax, ebx

    pop ebx
    
    ret

    ; print_unsigned(number, width, number_width)
    print_unsigned:
    push ebx
    push eax
    mov esi, eax ; char* out
    mov edi, eax ; save initial char* out
    mov eax, dword [esp + 12]
    ; ebx = max(width, number_width)
    mov ebx, dword [esp + 16]
    cmp ebx, dword [esp + 20]
    jge .continue
    mov ebx, dword [esp + 20]
    .continue:
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
    
    add esi, dword [esp + 24]
    dec esi
    jmp .after_minus
    .else_minus:
    lea esi, [esi + ebx - 1]
    .after_minus:
    mov ecx, 10 ; div 10 
    .loop:
    xor edx, edx
    div ecx
    add dl, '0'
    mov byte [esi], dl
    dec esi
    cmp eax, 0
    jne .loop

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
    jz .after_sign
    mov byte [esi], '+'
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
    jz .after_loop
    inc esi
    mov byte [esi], '+'
    dec esi

    .after_loop:
    pop ecx
    pop eax
    add eax, ebx
    pop ebx
    ret

    ; main function, strcpy now
    ; hw_sprintf(char* out, const char* format, ...) 
    hw_sprintf:

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
    
    .parse_percent:
    mov cl, byte [edx]
    cmp cl, '0'
    je .zero_flag
    cmp cl, '+'
    je .plus_flag
    cmp cl, '-'
    je .minus_flag
    cmp cl, ' '
    je .space_flag
    cmp cl, 'l'
    je .first_l
    cmp cl, 'u'
    je .unsigned
    cmp cl, 'd'
    je .signed
    cmp cl, '%'
    je .second_percent
    
    .incorrect_format:
    pop edx ; restore position before 
    mov byte [eax], '%'
    inc edx
    inc eax
    jmp .main_loop
    
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
    
    .unsigned:
    push edx
    push esi
    push ecx
    push eax
    ; call count_unsigned_length
    push dword [esi] ; vararg agrument
    call count_unsigned_length 
    add esp, 4
    mov edi, eax ; return value of count_unsigned_length
    pop eax      ; restore eax value
    pop ecx
    push ecx
    ; call print_unsigned
    ; print(number, width, number_width)
    ; fourth argument passed as eax /fastcall/
    push edi         ; number_width
    push 5  ;TODO    ; width
    push dword [esi] ; number 
    call print_unsigned
    add esp, 12
    ; eax is like a return value, it should be equal to it's value after [print_unsigned] call
    pop ecx
    pop esi
    pop edx
    add esi, 4 ; go to next vararg
    jmp .after_terminal
    
    .second_percent:
    mov byte [eax], '%'
    inc eax
    jmp .after_terminal 
   
    .signed:
    
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

