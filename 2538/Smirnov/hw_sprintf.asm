global hw_sprintf

%define FLAG_PLUS 1
%define FLAG_SPACE 2
%define FLAG_MINUS 4
%define FLAG_ZERO 8
%define FLAG_LONG_LONG 16 
%define FLAG_UNSIGNED 32
%define FLAG_NEGATIVE 64

%define MAX_INT32 0x80000000
%define MAX_UINT32 0xffffffff

%define BUFFER_SIZE 32

section .bss
buffer: resb BUFFER_SIZE
flags: resb 1
width: resd 1
arg: resd 1
tmp: resd 1

section .text
;void hw_sprintf(char *out, char const *format, ...);
hw_sprintf:
    ;save registers
    push    ebx
    push    edi
    push    esi
    push    ebp

    mov     edi, [esp + 20] ; pointer to output
    mov     esi, [esp + 24] ; pointer to input
    add     esp, 28
    mov     dword [arg], esp ; pointer to first argument
    sub     esp, 28

    .main_loop:
        call    .clean_buffer

        mov     byte [flags], byte 0 ; flags = 0
        mov     dword [width], 0 ; width = 0

        mov     ah, [esi] ; ah = current symbol
        inc     esi ; 
            
        cmp     ah, '%' 
        je      .set_flags
        jne     .write_current

        .set_flags:         
            mov     dword [tmp], esi ; remember esi in case of wrong arguments

        .next_flag:
            mov     ah, [esi] ; ah = next symbol
            inc     esi         
        
            ;checking '+' flag
            cmp     ah, '+' ; 
            jne     .no_sign
            or      byte [flags], byte FLAG_PLUS
            jmp     .next_flag

            ;checking ' ' flag
            .no_sign:
                cmp     ah, ' '
                jne     .no_space
                or      byte [flags], byte FLAG_SPACE
            jmp     .next_flag

            ;checking '-' flag
            .no_space:
                cmp     ah, '-'
                jne     .no_minus
                or      byte [flags], byte FLAG_MINUS
            jmp     .next_flag

            ;checking '0' flag
            .no_minus:
                cmp     ah, '0'
                jne     .no_zero
                or      byte [flags], byte FLAG_ZERO
            jmp     .next_flag

            .no_zero:
                ;if current symbol is not a digit then parse size else parse width
                cmp     ah, '1'
                jl      .set_size
                cmp     ah, '9'
                jg      .set_size

        ;jmp    .width_loop

        .width_loop:
            ; cl = current digit as int
            mov     cl, ah
            sub     cl, '0' 

            ;width = width * 10 + current digit
            mov     eax, 10
            mul     dword [width]
            mov     dword [width], eax
            add     byte [width], cl

            ;ah = next symbol
            mov     ah, [esi]
            inc     esi

            ;if next symbol is not a digit then parse size else continue parsing width
            cmp     ah, '0'
            jl      .set_size
            cmp     ah, '9'
            jg      .set_size
        jmp     .width_loop

        ;checking long long or int
        .set_size:
            cmp     ah, 'l'
            jne     .set_type
            mov     ah, [esi]
            inc     esi
            cmp     ah, 'l'
            jne     .wrong_type
            or      byte [flags], byte FLAG_LONG_LONG
            mov     ah, [esi]
            inc esi

        ;checking signed or unsigned or %
        .set_type:
            cmp     ah, '%' ; %
            je      .write_current
            cmp     ah, 'i' ; signed
            je      .write_number
            cmp     ah, 'd' ; signed
            je      .write_number
            cmp     ah, 'u' ; unsigned
            jne     .wrong_type ; no %, i, d, u => invalid params after '%'
            ;else set unsigned flag
            or      byte [flags], byte FLAG_UNSIGNED
        jmp     .write_number       

        .wrong_type:
            ;invalid params after %, so just write '%' and return to symbol after '%'
            mov     [edi], byte '%'
            inc     edi 
            mov     esi, dword [tmp] ; return to symbol after %
            mov     ah, [esi]   
            inc     esi
        jmp     .write_current

        ;following code writes number to buffer using ecx as pointer
        .write_number:
            ; eax = pointer to next argument        
            xor     edx, edx ; edx = 0
            mov     eax, dword [arg]
            add     dword [arg], 4
            ; eax = next argument
            mov     eax, [eax]

            test    byte [flags], byte FLAG_LONG_LONG
            jz      .write_int32    ; if not long long write int else long long
        ;jmp    .write_long_long

        .write_long_long
        ; long long, so we need 2 arguments
            mov     edx, eax
            mov     eax, dword [arg]
            add     dword [arg], 4
            mov     eax, [eax]

            test    byte [flags], byte FLAG_UNSIGNED
            jnz     .unsigned_long_long
            test    eax, MAX_INT32
            jz      .unsigned_long_long
            dec     edx
            cmp     edx, MAX_UINT32
            jne     .dec_not_needed
            dec     eax ; if 1st arg == MAX_UINT32

        .dec_not_needed: 
            not     edx 
            not     eax
            or      byte [flags], byte FLAG_NEGATIVE

        .unsigned_long_long:
            xor     ecx, ecx 

        .long_long_to_buffer_loop:
            ;following code calculates (long long number eax:edx) div 10 
            ;   and then writes result in buffer
            ; a = eax, b = edx          

            ;save registers
            push    ecx
            push    edx
            push    ebx
            push    eax
            push    edx     

            mov     ebp, esp
            ;calculating ebx = (b % 10 + (a % 10) * 6) % 10;
            ;b % 10
            xor     edx, edx
            mov     eax, dword [ebp]
            mov     ebx, 10
            div     ebx
            push    edx
            ;edx = a % 10
            xor     edx, edx
            mov     eax, dword [ebp + 4] ; dword [ebp + 4] = a
            div     ebx         
            ;eax = (a % 10) * 6
            mov     eax, 6
            mul     edx         
            ;eax = b % 10 + (a % 10) * 6
            pop     edx
            add     eax, edx            
            ;eax % 10
            xor     edx, edx
            div     ebx
            mov     dword [ebp + 8], edx ; dword[ebp + 8] = new ebx
            ;edx = a >> 29
            mov     edx, dword [ebp + 4]
            shr     edx, 29         
            ;eax = (a << 3) + (b >> 29)         
            mov     eax, dword [ebp + 4]
            shl     eax, 3
            mov     ebx, dword [ebp]
            shr     ebx, 29
            ;calc a = ((((a << 3) + (b >> 29))) / 10) >> 3
            add     eax, ebx
            mov     ebx, 10
            div     ebx
            shr     eax, 3
            mov     dword [ebp + 16], eax ; dword [ebp + 16] = new eax          
            ;b = ((2 ^ 32 * (a % 10) + b) / 10)
            xor     edx, edx
            mov     eax, dword [ebp + 4]
            div     ebx
            mov     eax, dword [ebp]
            div     ebx
            mov     dword [ebp + 12], eax ; dword [ebp + 12] = new edx
            add     esp, 8
            pop     ebx
            pop     edx
            pop     eax
        
        ;writing result in buffer

            add     bl, '0' ; converting to symbol
            mov     byte [buffer + ecx], bl
            inc     ecx
            cmp     eax, 0
            jne     .long_long_to_buffer_loop
            cmp     edx, 0
            jne     .long_long_to_buffer_loop

            jmp     .check_minus

        .write_int32:
            ;checking sign and xor + 1 if needed
            test    byte [flags], byte FLAG_UNSIGNED
            jnz     .unsigned_number
            test    eax, MAX_INT32
            jz      .unsigned_number
            dec     eax
            not     eax
            or      byte [flags], byte FLAG_NEGATIVE
            .unsigned_number:       
            ;ecx = 0 and ebx = 10 for writing buffer loop
            xor     ecx, ecx
            mov     ebx, 10
        jmp     .int32_to_buffer_loop       

        .check_minus:
        ;check flag and write minus if needed
            test    byte [flags], byte FLAG_NEGATIVE
            jz      .check_plus
            mov     dl, '-'
            mov     byte [buffer + ecx], dl
            inc     ecx

        .check_plus:
        ;check flags and write minus if needed
            test    byte [flags], byte FLAG_NEGATIVE
            jnz     .check_space
            test    byte [flags], byte FLAG_PLUS
            jz      .check_space
            mov     dl, '+'
            mov     byte [buffer + ecx], dl
            inc     ecx

        .check_space:
        ;check flags and write space if needed
            test    byte [flags], FLAG_SPACE
            jz      .not_space
            test    byte [flags], byte FLAG_NEGATIVE
            jnz     .not_space
            test    byte [flags], byte FLAG_PLUS
            jnz     .not_space
            mov     dl, ' '
            mov     byte [buffer + ecx], dl
            inc     ecx

        .not_space:
            push    ecx ; save ecx for writing          
            test    byte [flags], byte FLAG_MINUS ; if left align then write buffer
            jnz     .write_buffer
            cmp     dword [width], ecx  ; if width <= length of the number then just write buffer
            jle     .write_buffer       
            mov     ah, ' '
            test    byte [flags], byte FLAG_ZERO
            jz      .writing_space_and_zero_loop
            
            mov     ah, '0'
            mov     al, byte [buffer + ecx - 1]
            cmp     al, '0'
            jl      .write_first_symbol
            cmp     al, '9'
            jg      .write_first_symbol
        jmp     .writing_space_and_zero_loop

        .int32_to_buffer_loop:
            div     ebx
            add     dl, '0'
            mov     byte [buffer + ecx], dl
            inc     ecx
            xor     edx, edx
            cmp     eax, 0
            jne     .int32_to_buffer_loop
        jmp     .check_minus

        .write_first_symbol:
            dec     ecx
            mov     [edi], al
            inc     edi
            dec     dword [width]

        ;writing ah(space or zero) while width > length of the number
        .writing_space_and_zero_loop:
            mov     [edi], ah
            inc     edi
            dec     dword [width]
            cmp     dword [width], ecx
        jne     .writing_space_and_zero_loop            

        .write_buffer:
            dec     ecx
            mov     ah, byte [buffer + ecx] ; ah = current symbol from buffer
            mov     byte [edi], ah
            inc     edi
            cmp     ecx, 0
        jne     .write_buffer
            pop     ecx
            ;if left align > length && width > length of the number then write spaces
            test    byte [flags], byte FLAG_MINUS
            jz      .main_loop_end
            cmp     dword [width], ecx
            jng     .main_loop_end
        ;jmp        .writing_space_loop

        .writing_space_loop:
            mov     ah, ' '
            mov     [edi], ah
            inc     edi
            inc     ecx
            ;if width == written count break
            cmp     dword [width], ecx
            je      .main_loop_end
        jmp     .writing_space_loop

        ;writes current symbol to output
        .write_current:
            mov     [edi], ah
            inc     edi
        ;jmp        .main_loop_end              

        .main_loop_end:
            cmp     ah, 0 ; check end of string
    jne     .main_loop

    pop     ebp
    pop     esi
    pop     edi
    pop     ebx
ret

;buffer = [0, 0, 0...]
.clean_buffer:
    xor     ecx, ecx
    .clean_buffer_loop:
        mov     byte [buffer + ecx], ch
        inc     ecx
        cmp     ecx, BUFFER_SIZE
    jne     .clean_buffer_loop
ret