global hw_sprintf

%define FLAG_ZERO  1
%define FLAG_PLUS  2
%define FLAG_MINUS 4
%define FLAG_SPACE 8
%define FLAG_LONG  16
%define FLAG_WIDTH 32
%define FLAG_SIGN  64

section .text

    ; int count_length(64-bit number)
    ; returns length of string representation of "number"
    ; according to flags
    ; /fastcall/ ch contains flags
    count_length:
    
    push ebx
    push esi
                
    xor ebx, ebx       ; stores current length of number
    mov eax, dword [esp + 12]  ; 1st half of number
    mov edx, dword [esp + 16]  ; 2nd half of number

    test ch, FLAG_LONG ; hack for determination 
    jz .after_swap     ; sign of number
    xchg eax, edx      ; in code below tests higher bit of eax
    .after_swap:       ; so let's swap edx:eax if number is long
            
    mov cl, '+'            ; cl will store char for sign of number
    test eax, 0x80000000   ; test if higher bit of eax is set
    jz .after_change_sign  
    test ch, FLAG_SIGN     ; if higher bit is 1 and number is signed
    jz .after_change_sign
    mov cl, '-'            ; new sign char if '-'
    
    test ch, FLAG_LONG
    jz .32bit_complement
    .64_complement:
    not eax       ; conversion from two's complement for 64-bit value
    not edx       ; ~(eax:edx) + 1
    add edx, 1    ; eax:edx because we reversed number for sign determination hack higher
    adc eax, 0    ; add edx, 1 instead of inc edx because inc does not set flags
    jmp .after_change_sign
    .32bit_complement:        
    neg eax       ; from two's complement to absolute value
    .after_change_sign:

                     
    test ch, FLAG_LONG ; let's swap halves of number back if we did
    jz .after_swap1 
    xchg eax, edx
    .after_swap1:

    test ch, FLAG_PLUS + FLAG_SPACE
    jnz .to_inc
    cmp cl, '-'
    je .to_inc
    jmp .after_inc
    .to_inc:
    inc ebx     ; result + 1 if sign prints (number < 0, '+' or ' ' flag is set)
    .after_inc:
    
    mov ecx, 10 ; for div 10 

    mov esi, ebx
     
    .loop64:
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
    cmp edx, 0
    jne .loop64
    cmp eax, 0
    je  .after_loop32 ; kind of optimization:
    jmp .loop32       ; when edx == 0 our 64-bit value became 32-bit
    .after_loop32:    ; so go to the 32-bit loop, it is faster
    mov eax, esi
    
    jmp .after_loops
    
    .loop32:
    xor edx, edx
    div ecx
    inc esi
    cmp eax, 0
    jne .loop32
    mov eax, esi
    
    
    .after_loops:
    
    pop esi
    pop ebx
    
    ret

    ; print_number(number, width, number_width)
    print_number:
    
    push ebx
    push eax
    
    mov esi, eax ; char* out
    mov edi, eax ; save initial char* out
    mov eax, dword [esp + 12] ; 1st half of number
    mov edx, dword [esp + 16] ; 2nd half of number  
    ; ebx = max(width, number_width)
    mov ebx, dword [esp + 20] ; number_width
    cmp ebx, dword [esp + 24] ; if ebx < width
    jge .continue
    mov ebx, dword [esp + 24] ; ebx = width
    .continue:
    
    test ch, FLAG_LONG ; swap halves trik again
    jz .after_swap     ; just as in count_length
    xchg eax, edx
    .after_swap:
    
    mov cl, '+'
    test eax, 0x80000000  ; test higher bit again
    jz .after_change_sign 
    test ch, FLAG_SIGN
    jz .after_change_sign
    mov cl, '-'
    
    test ch, FLAG_LONG    ; convert from two's complement
    jz .32bit_complement
    .64_complement:
    
    not eax
    not edx        
    add edx, 1
    adc eax, 0
    
    jmp .after_change_sign
    .32bit_complement:        
    neg eax               ; from two's complement to absolute value
    .after_change_sign:
    
    test ch, FLAG_LONG    ; swap them back
    jz .after_swap2 
    xchg eax, edx
    .after_swap2:
    
    push ecx
    test ch, FLAG_MINUS
    jz .else_minus
    
    push esi                  ; left alignment if '-' flag is set
    lea esi, [esi + ebx - 1]
    .fill_space:
    mov byte [esi], ' '
    dec esi
    cmp esi, edi
    jge .fill_space
    pop esi
    
    add esi, dword [esp + 28] ; jump to the end of number to print it
    dec esi
    jmp .after_minus
    .else_minus:
    lea esi, [esi + ebx - 1]
    .after_minus:
    
    mov ecx, 10 ; for div 10 
    
    push ebx
    
    .loop64:
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
    cmp edx, 0
    jne .loop64
    cmp eax, 0
    je  .after_loops
    ; jmp .loop32 -- just goes to the next string automatically
    ; jump to loop32 is intended, not accident
    ; the loop is splitted into two partes: 64-bit and 32-bit
    ; 64-bit cycle divides numbers with eax > 0 (edx:eax)
    ; when edx became 0, we can divide 32-bit value (0:eax)
    
    .loop32:
    xor edx, edx
    div ecx
    add dl, '0'
    mov byte [esi], dl
    dec esi
    cmp eax, 0
    jnz .loop32    
    
    .after_loops:
    
    
    pop ebx

    pop ecx ; refresh ch, contains flags
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

    ; set sign before number if spaces: "      [sign][number]"
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
    
    ; replace last '0' symbol to sign: "000000[number]" -> "[sign]00000[number]"
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
    add eax, ebx ; move pointer to the end of string after printed number
    pop ebx      ; eax is a returned value of print_number (new position is string)
    
    ret

    ; hw_sprintf(char* out, const char* format, ...) 
    hw_sprintf:

    ; all registers: eax, ebx, ecx, edx, esi, edi
    ; cdecl declare callee need to save ebx, esi, edi
    push ebx
    push esi
    push edi

    xor ebx, ebx        ; initially width = 0
            
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
    
    test ch, FLAG_LONG  ; if ll has already read
    jnz .after_width    ; jump to read only {d,i,u,%}
    
    test ch, FLAG_WIDTH ; if width has already read
    jnz .after_width    ; jump to read only [ll]{d,i,u,%}
    
    ; switch-case by cl symbol
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
    cmp cl, 'l'
    je .first_l
    
    .after_long:
    cmp cl, '%'
    je .second_percent
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
  
    ; parsing of width
    .read_width:
    xor ebx, ebx ; initialization, width = 0
    push eax
    .width_loop:
        mov cl, byte [edx]    ; read next char
        cmp cl, '0'           ; if it is not in range ['0'..'9'] -- exit  
        jl .after_width_loop
        cmp cl, '9'
        jg .after_width_loop
        inc edx  ; go to next symbol

        ; save some registers
        push edx
        push ecx
        
        mov eax, ebx ; (0:ebx) * 10
        mov ecx, 10  
        mul ecx
        
        pop ecx
        push ecx
        sub cl, '0'
        and ecx, 0x000000FF ; only least 8 bits store useful information
        lea ebx, [eax + ecx]
                                                                        
        pop ecx ; restore registers value
        pop edx
        
        jmp .width_loop
    .after_width_loop:
    pop eax    
    or ch, FLAG_WIDTH
    jmp .parse_percent

    ; set some flags        
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
    mov cl, byte [edx]    ; if read 'l' read another symbol
    cmp cl, 'l'           ; if it is not another 'l' this token is incorrect
    jne .incorrect_format ; we read only 1 symbol, so even if first 'l' was the last
    or ch, FLAG_LONG      ; symbol in string we will read '\0' symbol and not read out ouf bounds
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
    ; call count_length
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
    call count_length 
    add esp, 8
    mov edi, eax ; return value of count_length
    pop eax      ; restore eax value
    pop ecx
    push ecx
    ; call print_number
    ; print(number, width, number_width)
    ; fourth argument passed as eax /fastcall/
    push edi         ; number_width
    push ebx ; width
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
    call print_number
    add esp, 16
    ; eax is like a return value, it should be equal to it's value after [print_number] call
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
