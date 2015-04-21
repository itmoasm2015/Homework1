global hw_sprintf

section .bss

; The string representation of the current argument is storing here.
; 128 bytes reserved for it.
st_rep: resb 128  
                        
section .text

; Function satisfying signature void hw_sprintf(char *out, char const *format, ...);
; Flags are storing in register ebx, width - in edx
hw_sprintf:
    push ebp
    mov ebp, esp
    push esi
    push edi
    
    ; Register esi will be output buffer
    ; Register edi will be format string
    ; Register ecx - it is first argument
    mov edi, [ebp + 8]
    mov esi, [ebp + 12] 
    lea ecx, [ebp + 16]

next:
    ; If the '%' character has detected, we are parsing format sequence
    cmp byte [esi], '%' 
    je parsing
    
    ; There is a format string in edi, so let's move non-format character to edi
    movsb
    
    ; Compare string with 0. If 0 - it is end, else - let's continue.
    cmp byte [esi - 1], 0 
    je .done
    jne next
    
; End    
.done:
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret

; Parsing function. It also sets flags
parsing:
    ; Saving position, because format sequence can be invalid
    ; Сlean up the auxiliary registers
    ; Register esi - next symbol (after '%')
    push esi
    mov ebx, 0
    mov edx, 0
    mov eax, 0
    inc esi

; Get flags and set them in register ebx;
.s_flags:
    lodsb
    
    cmp al, '+'
    je .s_plus
    
    cmp al, '-'
    je .s_neg
    
    cmp al, ' '
    je .s_space
    
    cmp al, '0'
    je .s_zero

; Calculate width in register edx and store it on the stack
.width:
    ; if current symbol is not a digit skip this step
    cmp al, '0'
    jb .done

    cmp al, '9'
    ja .done

    imul edx, 10
    sub eax, '0'
    add edx, eax

    lodsb
    jmp .width

.done:
    push edx

; If 'll' detected, set LONG_LONG
.long:
    ; Last 'lodsb' might have moved ESI to point to the second "l"
    dec esi
    
    ; If the number is 32-bit proceed to parse type modifier
    cmp word [esi], 'll'
    jne .unsign   
    
    ; Jump over 'll'
    add esi, 2
    
     ; 64-bit number, set LONG_LONG
    or ebx, LONG_LONG

; If '%u' detected, set UNSIGNED
.unsign:
    lodsb
    cmp al, 'u'
    je .s_unsigned

    cmp al, 'i'
    je .parsing_done

    cmp al, 'd'
    je .parsing_done

    cmp al, '%'
    je .output_percent

    jmp .invalid_seq

; Set PLUS, and go back
.s_plus:
    or ebx, PLUS
    jmp .s_flags

; Set ALIGN_LEFT, and go back
.s_neg:
    or ebx, ALIGN_LEFT
    jmp .s_flags

; Set SPACE, and go back
.s_space:
    or ebx, SPACE
    jmp .s_flags

; Set ZEROPAD, and go back
.s_zero:
    or ebx, ZEROPAD
    jmp .s_flags

; Set UNSIGNED, sequence is valid and parsing is done.
.s_unsigned:
    or ebx, UNSIGNED
    jmp .parsing_done

; Format sequence had type % in it
.output_percent ;
    ; Width is not necessary now
    ; Moving '%' to output
    add esp, 4
    stosb 
    jmp next

; Valid format sequence - ok.
.parsing_done
    jmp out_seq

; Invalid format sequence
.invalid_seq
    ; Width is not necessary now
    add esp, 4
    
    ; Restore position in string to the beginning of format sequence. ( We providently saved it )
    pop esi 
    
    ; Moving '%' character to output buffer and continue
    movsb   
    jmp next

; Preparing number (EDX:EAX) and output
; Difference between 32- and 64 - bit numbers: register edx in case of 32-bit number is 0
out_seq:
    ; If number is 64-bit
    test ebx, LONG_LONG
    jnz .int64

.int32:
    ; If number is 32-bit
    mov edx, 0 
    ; Move current argument to register eax
    mov eax, [ecx] 
    add dword ecx, 4 ; move ECX  to point to the next argument
    ; If number is unsigned - done
    test ebx, UNSIGNED
    jnz .done

    cmp eax, 0
    jl .negative_int32
    jmp .done

; If number is negative
.negative_int32:
    ; Set flag
    or ebx, NEGATION
    ; Negate number
    neg eax
    jmp .done

.int64:
    ; Move number to EAX:EDX
    mov eax, [ecx]         
    mov edx, [ecx + 4]
    add dword ecx, 8

    test ebx, UNSIGNED
    jnz .done

    cmp edx, 0
    jl .negative_int64
    jmp .done

; Do the same thing for 64 bit numbers
; To negate long number we are inverting all bits and adding 1
.negative_int64:
    ; Set flag
    or ebx, NEGATION
    not eax
    not edx
    add eax, 1
    adc edx, 0 

.done:
    ; If the number is padded with zeros output sign if present
    test ebx, ZEROPAD
    jz .calc_padding
    call put_first_symbol

; Calculate neeeded padding length and perform padding
.calc_padding:
    push edi
    mov  edi, st_rep
    call itoa
    pop edi
    test ebx, PLUS|SPACE|NEGATION
    jz .check_if_fits
    inc eax

.check_if_fits:
    ; Compare calculated length with width parameter
    cmp eax, [esp] 
    ; If the number length is at least equal to width parameter do no padding
    jge .pad_left_finished 

.has_padding:
    ; [ESP] = width
    mov edx, [esp]  
    ; edx = padding length     
    sub edx, eax         
    jmp .pad_left

.pad_left:
     ; If found dont do any left padding
    test ebx, ALIGN_LEFT
    jnz .pad_left_finished

    push eax
    mov eax, ' '
    test ebx, ZEROPAD
    jz .pad_left_loop
    mov eax, '0'

.pad_left_loop:
    mov [edi], al
    inc edi
    dec edx
    jnz .pad_left_loop

.pad_left_finished:
    pop eax
     ; If we performed space padding output the sign now
    test ebx, ZEROPAD
    jnz .put_number_from_buffer
    call put_first_symbol

; Print an additional symbol and the number from buffer to destination buffer of hw_sprintf
.put_number_from_buffer:
    test ebx, PLUS|SPACE|NEGATION
    push esi             
    mov esi, st_rep

.put_number_loop:
    cmp byte [esi], 0
    je .pad_right

    movsb
    jmp .put_number_loop

.pad_right:
    ; Restore source buffer pointer
    pop esi   

    test ebx, ALIGN_LEFT
    jz .pad_right_finished
    
    ; Number is alligned left and ZEROPAD not needed
    mov eax, ' '              
    jz .perform_padding_right

.perform_padding_right:
    cmp edx, 0
    jle .pad_right_finished

.pad_right_loop:
    mov [edi], al
    inc edi
    dec edx
    jnz .pad_right_loop

.pad_right_finished
    xor eax, eax
    xor edx, edx
    jmp next

; Puts first symbol to the output buffer specified by register edi, considering sign and flags
put_first_symbol:
    test ebx, NEGATION
    jnz .put_minus

    test ebx, PLUS
    jnz .put_plus

    test ebx, SPACE
    jnz .put_space
    jmp .ret

.put_minus:
    mov byte [edi], '-'
    inc edi
    jmp .ret

.put_plus:
    mov byte [edi], '+'
    inc edi
    jmp .ret

.put_space:
    mov byte [edi], ' '
    inc edi
    jmp .ret

.ret:
    ret


; Moves number (EAX:EDX) to buffer specified by register edi ( Length of the number in eax )
itoa:
    ;  Save flags and argument pointer
    push    edi
    push    ebx       
    push    ecx

    ; Terminating null
    push    byte 0      
    mov     ecx, 10

; Get reversed string representation on the stack
.div_loop
    push eax         ; save EAX
    mov  eax, edx    ; EAX:EDX -> EDX:EDX
    xor  edx, edx    ; EDX:EDX -> EDX:0
    div  ecx         ; div EDX by 10
    mov  ebx, eax    ; save quotient in EBX
    pop  eax
    div  ecx         ; div EAX by 10
    xchg ebx, edx    ; we now have EDX / 10 : EAX / 10, and the remainder in EBX
    add  bl, '0'
    dec  esp
    mov  [esp], bl
    cmp  eax, 0
    jne  .div_loop

 ; Move string from the stack to output buffer and reverse it in the process
.reverse
    mov  bl, [esp]
    inc  esp
    mov  [edi], bl
    inc  edi
    cmp  bl, 0
    jne  .reverse

    lea     eax, [edi - 1]        
    add     esp, 3                
    pop     ecx
    pop     ebx
    ; After we pop edi, [EDI] = beginning of the number, and sub eax, edi = string length
    pop     edi
    sub     eax, edi
    ret
   
; Flags
PLUS equ 1
ALIGN_LEFT equ 2
SPACE equ 4
LONG_LONG equ 8
ZEROPAD equ 16
UNSIGNED equ 32
NEGATION equ 64
