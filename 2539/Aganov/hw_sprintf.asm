global hw_sprintf

section .text

; void hw_sprintf(char* out, char const *format, ...)
hw_sprintf:
    ;eax, ecx, edx are saved by caller
    push    ebx
    push    edi
    push    esi
    push    ebp


    ;edi - out, esi - format, argument - pointer to the first argument
    mov     edi, [esp + 20]
    mov     esi, [esp + 24]
    add     esp, 28
    mov     dword [argument], esp
    sub     esp, 28

    ;flags = 0
    mov     ecx, 0
    mov     byte [flag], byte 0
    ;width = 0
    mov     dword [width], 0
    ;buffer set 0
.pre_zeroing_buffer:
    mov     byte [buffer + ecx], ch; ecx < 20 so ch = 0    
    inc     ecx
    cmp     ecx, 20
    jne     .pre_zeroing_buffer

    ;start parsing
.parser:
    ;ah - current symbol
    mov     ah, [esi]
    inc     esi
    ;if current symbol is '%' then start percent processing
    cmp     ah, '%'
    je     .percent_processing
    ;else just write current symbol
.write_current:
    mov     [edi], ah
    inc     edi
    
.end:
    ;if current symbol is zero then stop parsing
    cmp     ah, 0
    jne     .parser
    ;function is done
    pop     ebp
    pop     esi
    pop     edi
    pop     ebx
    ret



.percent_processing:    
    mov     ah, [esi]
    inc     esi

    ;if '%%' then write '%'
    cmp     ah, '%'
    je     .write_current

    jmp     .check_flags

    
    ;we already got % later
.percent_processing_continue:
    mov     ah, [esi]
    inc     esi

.check_flags:
    ;check '+', '-', ' ', '0' and write in flags 
    cmp     ah, '+'
    jne     .not_sign
    or      byte [flag], byte 8
    jmp     .percent_processing_continue
.not_sign:

    cmp     ah, ' '
    jne      .not_space
    or      byte [flag], byte 4
    jmp     .percent_processing_continue
.not_space:

    cmp     ah, '-'
    jne      .not_left_align
    or      byte [flag], byte 2
    jmp     .percent_processing_continue
.not_left_align:

    cmp     ah, '0'
    jne      .not_zero_complement
    or      byte [flag], byte 1
    jmp     .percent_processing_continue
.not_zero_complement:


    ;width reading if first symbol is a digit
    cmp     ah, '1'
    jl      .not_width
    cmp     ah, '9'
    jg      .not_width

.width_reading_loop:    
    ;every time width = width * 10 + current_symol - '0'
    mov     cl, ah
    sub     cl, '0'
    mov     eax, 10
    mul     dword [width]
    mov     dword [width], eax
    add     dword [width], ecx
    mov     ah, [esi]
    inc     esi
    cmp     ah, '0'
    jl      .not_width
    cmp     ah, '9'
    jg      .not_width
    jmp     .width_reading_loop
.not_width:

    ;check ll
    cmp     ah, 'l'    
    jne     .not_long_long
    mov     ah, [esi]
    inc     esi
    cmp     ah, 'l'    
    jne     .start_finding_procent
    or      byte [flag], byte 16
    mov     ah, [esi]
    inc     esi
.not_long_long:

    
    ;check i, d, u
    cmp     ah, 'i'
    je      .write_number

    cmp     ah, 'd'
    je      .write_number

    cmp     ah, 'u'
    je      .write_unsigned_number

    ;else there is '%'* well then write '%'*    
    ;we need to write all symbols after % which we read
    ;so we jump to symbol next to '%' and write '%'

    ;dec because current symbol can be '%'
.start_finding_procent:
    dec     esi
.find_procent:
    dec     esi
    mov     al, '%'
    cmp     [esi], al
    jne     .find_procent

    mov     [edi], byte '%'
    mov     ah, [edi]
    inc     edi
    inc     esi

    jmp     .end_percent_processing

.write_number:
    ;writing number

    ;get argument to eax
    mov     edx, 0
    mov     eax, dword [argument]
    add     dword [argument], 4
    mov     eax, [eax]

    ;long long?
    test     byte [flag], byte 16
    jz       .just_int
    
    ;read next 32bit argument
    mov     edx, eax
    mov     eax, dword [argument]
    add     dword [argument], 4
    mov     eax, [eax]


    

    ;xor + 1 eax, edx and sets flag if signed    
    test    byte [flag], byte 32
    jnz     .unsigned_long_long
    test    eax, 0x80000000
    jz      .unsigned_long_long
    
    sub     edx, 1
    cmp     edx, 0xffffffff
    jne     .no_dec1    
    sub     eax, 1
.no_dec1:    
    not     edx
    not     eax
    ;write minus flag
    or      byte [flag], byte 128
.unsigned_long_long:

    mov     ecx, 0
.long_long_to_buffer_loop:
    ;div 10:
    ;current number is (eax << 32) + edx
    ;quotient will be also (eax << 32) + edx
    ;module will be ebx
    push    ebp
    push    ecx
    jmp     .div10_long_long
.end_div10_long_long:
    pop     ecx
    pop     ebp
    add     bl, '0'
    mov     byte [buffer + ecx], bl
    inc     ecx

    cmp     eax, 0
    jne     .long_long_to_buffer_loop
    cmp     edx, 0
    jne     .long_long_to_buffer_loop    
    


    ;skip code for int
    jmp     .from_long_long       

.just_int:    

    ;xor + 1 and sets flag if signed
    test    byte [flag], byte 32
    jnz     .unsigned_number
    test    eax, 0x80000000
    jz      .unsigned_number
    dec     eax
    not     eax
    ;write minus flag
    or      byte [flag], byte 128
.unsigned_number:

    ;write number to buffer 
    mov     ecx, 0
    mov     ebx, 10
.int_to_buffer_loop:
    div     ebx
    add     dl, '0'
    mov     byte [buffer + ecx], dl
    inc     ecx
    mov     edx, 0

    cmp     eax, 0
    jne     .int_to_buffer_loop

.from_long_long:

    ;write '-' if needed
    test    byte [flag], byte 128
    jz      .minus_not_needed
    mov     dl, '-'
    mov     byte [buffer + ecx], dl
    inc     ecx
.minus_not_needed:

    ;write '+' if needed
    test    byte [flag], byte 128
    jnz     .plus_not_needed
    test    byte [flag], byte 8
    jz      .plus_not_needed
    mov     dl, '+'
    mov     byte [buffer + ecx], dl
    inc     ecx    
.plus_not_needed:

    ;write ' ' if needed
    test    byte [flag], 4
    jz      .space_not_needed
    test    byte [flag], byte 128
    jnz     .space_not_needed
    test    byte [flag], byte 8
    jnz     .space_not_needed
    mov     dl, ' '
    mov     byte [buffer + ecx], dl
    inc     ecx    
.space_not_needed:       



    push    ecx; save ecx for future writing_space_loop_2
    
    
    ;if left_align then just copy
    test    byte [flag], byte 2
    jnz     .buffer_to_out_loop

    ;if width <= length of the number then just copy
    cmp     dword [width], ecx
    jng     .buffer_to_out_loop

    ;writing ' ' or '0' while width > length of the number
    push    dword [width]; save width for a future...

    mov     ah, ' '
    test    byte [flag], byte 1
    jz      .writing_space_or_zero_loop
    
    ;'0' writing
    mov     ah, '0'
    mov     al, byte [buffer + ecx - 1]

    cmp     al, '0'
    jl      .write_first_symbol
    cmp     al, '9'
    jg      .write_first_symbol
    jmp     .writing_space_or_zero_loop

.write_first_symbol:
    dec     ecx
    mov     byte [width + ecx], 0;idk why    
    mov     [edi], al
    inc     edi
    dec     dword [width]



.writing_space_or_zero_loop:
    mov     [edi], ah
    inc     edi
    dec     dword [width]
    cmp     dword [width], ecx        
    jne     .writing_space_or_zero_loop

    pop     dword [width]

    
.buffer_to_out_loop:
    dec     ecx
    mov     ah, byte [buffer + ecx]
    mov     byte [edi], ah
    inc     edi

    cmp     ecx, 0
    jne     .buffer_to_out_loop
    
    pop     ecx
    ;if left_align and width > length of the number then writing spaces
    test    byte [flag], byte 2
    jz     .end_percent_processing
    cmp     dword [width], ecx
    jng     .end_percent_processing      
.writing_space_loop_post:
    mov     ah, ' '
    mov     [edi], ah
    inc     edi
    inc     ecx
    cmp     dword [width], ecx        
    jne     .writing_space_loop_post


.end_percent_processing:
    

    ;flag = 0
    mov     al, byte 0
    mov     byte [flag], al

    ;width = 0
    mov     ecx, 0
    mov     dword [width], ecx

    ;buffer[] set 0
.zeroing_buffer:
    mov     byte [buffer + ecx], ch; ecx < 20 so ch = 0    
    inc     ecx
    cmp     ecx, 20
    jne     .zeroing_buffer

    jmp     .end


.write_unsigned_number:
    or      byte [flag], byte 32
    jmp     .write_number    


.div10_long_long:
    ;eax = a
    ;edx = b
    ;module = future ebx = (b % 10 + (a % 10) * 6) % 10;
    ;new a = future eax = (((1ll * (a << 3) + (b >> 29))) / 10) >> 3;
    ;new b = future edx = (((1ll << 32) * (a % 10) + b) / 10);
    push    eax
    push    edx
    push    ebx
    push    eax
    push    edx
    mov     ebp, esp
    ;dword [ebp + 16] = new eax
    ;dword [ebp + 12] = new edx
    ;dword [ebp + 8] = new ebx = modulo
    ;dword [ebp + 4] = old eax = a
    ;dword [ebp] = old edx = b
    
    ;calculating module
    ;b % 10
    mov     edx, 0
    mov     eax, dword [ebp]
    mov     ebx, 10
    div     ebx
    push    edx

    ;a % 10
    mov     edx, 0
    mov     eax, dword [ebp + 4]
    div     ebx
    ;result in edx
    
    ;(a % 10) * 6
    mov     eax, 6
    mul     edx
    ;result in eax

    ;b % 10 + (a % 10) * 6
    pop     edx
    add     eax, edx
    ;result in eax

    ;eax % 10
    mov     edx, 0
    div     ebx
    mov     dword [ebp + 8], edx

    ;calculating new a = future eax = (((1ll * (a << 3) + (b >> 29))) / 10) >> 3
    ;in edx should be a >> 29
    ;in eax should be (a << 3) + (b >> 29)
    mov     edx, dword [ebp + 4]
    shr     edx, 29

    mov     eax, dword [ebp + 4]
    shl     eax, 3
    mov     ebx, dword [ebp]
    shr     ebx, 29
    add     eax, ebx

    mov     ebx, 10
    div     ebx
    shr     eax, 3
    mov     dword [ebp + 16], eax

    ;calculating new b = future edx = (((1ll << 32) * (a % 10) + b) / 10)
    ;in edx should be a % 10
    ;in eax should be b
    mov     edx, 0
    mov     eax, dword [ebp + 4]
    div     ebx

    mov     eax, dword [ebp]

    div     ebx

    mov     dword [ebp + 12], eax

    add     esp, 8
    pop     ebx
    pop     edx
    pop     eax
    jmp     .end_div10_long_long



section .bss
buffer:       resb 20
flag:         resb 1
;flag tests:
;1 - zero complement
;2 - left aling
;4 - space
;8 - sign
;16 - long long
;32 - unsigned
;64 - minus
width:        resd 1
argument:     resd 1
