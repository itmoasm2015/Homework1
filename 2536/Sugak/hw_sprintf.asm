global hw_sprintf

%define PLUS_FLAG 1
%define ALLIGN_LEFT_FLAG 2
%define SPACE_FLAG 4
%define LONG_LONG_FLAG 8
%define ZEROPAD_FLAG 32
%define UNSIGNED_FLAG 64
%define IS_NEGATIVE_FLAG 128

%define setf(f) or ebx, f ; macro to conviniently set flags
%define testf(f) test ebx, f ; macro to test if flag is set

section .bss
buffer: resb 50  ; buffer where string representation of the current argument is stored

section .text

;void hw_sprintf(char *out, char const *format, ...);
hw_sprintf:
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov edi, [ebp + 8] ; ESI points to output buffer
    mov esi, [ebp + 12] ; EDI points to format string
    lea ecx, [ebp + 16] ; pointer to first argument

next_character:
    cmp byte [esi], '%' ; if % is found we should try to parse format sequence
    je parse_format_sequence

    movsb ; non format character => move it from ESI to EDI

    cmp byte [esi - 1], 0 ; since string are null terminated finding 0 means we have reached the end
    je .completed
    jne next_character

.completed:
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret

;function that parses format parameters and sets respective flags
;flags are stored in EBX register, width is stored in EDX
parse_format_sequence:
    push esi     ; save position in string in case format sequence is invalid
    xor ebx, ebx ; clear the "flag" register
    xor edx, edx ; clear width
    xor eax, eax ; clear AL to be read to
    inc esi      ; ESI now points to first symbol after %

;parse flags(+, -, space, 0) and set bits of EBX accordingly;
.flag_parse_loop:
    lodsb

    cmp al, '+'
    je .set_plus_flag

    cmp al, '-'
    je .set_minus_flag

    cmp al, ' '
    je .set_space_flag

    cmp al, '0'
    je .set_zeropad_flag

;calculate the width parameter (if present) in EDX register and store it on the stack
.get_width_loop:
    ; if current symbol is not a digit skip this step
    cmp al, '0'
    jb .get_width_loop_finished

    cmp al, '9'
    ja .get_width_loop_finished

    imul edx, 10
    sub eax, '0'
    add edx, eax

    lodsb
    jmp .get_width_loop

.get_width_loop_finished:
    push edx

;set LONG_LONG_FLAG if format sequence contains ll parameter
.get_size_loop:
    dec esi               ; last lodsb instruction might have moved ESI to point to the second "l"
    cmp word [esi], 'll'
    jne .get_type_loop    ; the number is 32-bit => proceed to parse type modifier

    add esi, 2            ; move ESI by 2 since we just read "ll"
    setf(LONG_LONG_FLAG)  ; the number is 64-bit so the LONG_LONG_FLAG flag is set

;sets UNSIGNED_FLAG if the number to be formatted is unsigned %u
.get_type_loop:
    lodsb
    cmp al, 'u'
    je .set_type_flag

    cmp al, 'i'
    je .successfully_parsed

    cmp al, 'd'
    je .successfully_parsed

    cmp al, '%'
    je .output_percent

    jmp .invalid_format_sequence

.set_plus_flag:
    setf(PLUS_FLAG)
    jmp .flag_parse_loop

.set_minus_flag:
    setf(ALLIGN_LEFT_FLAG)
    jmp .flag_parse_loop

.set_space_flag:
    setf(SPACE_FLAG)
    jmp .flag_parse_loop

.set_zeropad_flag:
    setf(ZEROPAD_FLAG)
    jmp .flag_parse_loop

.set_type_flag:
    setf(UNSIGNED_FLAG)
    jmp .successfully_parsed

.output_percent ; format sequence had type % in it
    add esp, 4 ; no need to store width anymore
    stosb ; move % to output, AL -> EDI
    jmp next_character

.successfully_parsed      ; the format sequence was valid
    jmp do_output

.invalid_format_sequence
    add esp, 4 ; no need to store width anymore
    pop esi ; restore position in string to the beginning of format sequence
    movsb   ; move % to output buffer and proceed on reading a string
    jmp next_character

;this function perfoms operation necessary to prepare number to be output and then outputs it
;the number to be output is stored in EDX:EAX
;64-bit and 32-bit numbers are treated similarly in a way that both are stored in two registers
;but 32-bit's EDX is zero
do_output:
    testf(LONG_LONG_FLAG) ; check if the number is 64-bit
    jnz .int64

.int32:
    xor edx, edx     ; 32-bit => EDX = 0
    mov eax, [ecx]   ; load current argument to EAX
    add dword ecx, 4 ; move ECX  to point to the next argument

    testf(UNSIGNED_FLAG)  ; if number is unsigned nothing needs to be done
    jnz .done

    cmp eax, 0
    jl .negative_int32
    jmp .done

; if the number is < 0 negate it and set IS_NEGATIVE_FLAG
.negative_int32:
    setf(IS_NEGATIVE_FLAG)
    neg eax
    jmp .done

.int64:
    mov eax, [ecx]         ;   load number to EAX:EDX
    mov edx, [ecx + 4]
    add dword ecx, 8

    testf(UNSIGNED_FLAG)
    jnz .done

    cmp edx, 0
    jl .negative_int64
    jmp .done

;do the same thing for 64 bit numbers
.negative_int64:
    setf(IS_NEGATIVE_FLAG)

    not eax
    not edx
    add eax, 1 ; can't use inc since it doesn't set CF
    adc edx, 0 ; invert all bits and add 1 <=> negate long number

.done:
    testf(ZEROPAD_FLAG)   ; if the number is padded with zeros output sign if present
    jz .calc_padding
    call put_first_symbol

; calculate neeeded padding length and perform padding
.calc_padding:
    push edi
    mov  edi, buffer
    call itoa
    pop edi
    testf(PLUS_FLAG|SPACE_FLAG|IS_NEGATIVE_FLAG)
    jz .check_if_fits
    inc eax

.check_if_fits:
    cmp eax, [esp]  ; compare calculated length with width parameter
    jge .pad_left_finished ; if the number length is at least equal to width parameter do no padding

.has_padding:
    mov edx, [esp]       ; [ESP] = width parameter
    sub edx, eax         ; EDX = padding length
    jmp .pad_left

.pad_left:
    testf(ALLIGN_LEFT_FLAG) ; if found dont do any left padding
    jnz .pad_left_finished

    push eax
    mov eax, ' '
    testf(ZEROPAD_FLAG)
    jz .pad_left_loop
    mov eax, '0'

.pad_left_loop:
    mov [edi], al
    inc edi
    dec edx
    jnz .pad_left_loop

.pad_left_finished:
    pop eax
    testf(ZEROPAD_FLAG)         ; if we performed space padding output the sign now
    jnz .put_number_from_buffer
    call put_first_symbol

;print an additional symbol (if present) and then prints the number from buffer to destination buffer of hw_sprintf
.put_number_from_buffer:
    testf(PLUS_FLAG|SPACE_FLAG|IS_NEGATIVE_FLAG)
    push esi             ; i do it just to be able to move chars move conviniently with movsb
    mov esi, buffer

.put_number_loop:
    cmp byte [esi], 0
    je .pad_right

    movsb
    jmp .put_number_loop

.pad_right:
    pop esi   ; restore source buffer pointer

    testf(ALLIGN_LEFT_FLAG)
    jz .pad_right_finished

    mov eax, ' '               ; since the number is alligned left we dont care if ZEROPADD_FLAG is set
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
    jmp next_character

;puts first symbol to the output buffer specified by EDI
;depending on the flags and sign.
put_first_symbol:
    testf(IS_NEGATIVE_FLAG)
    jnz .put_minus

    testf(PLUS_FLAG)
    jnz .put_plus

    testf(SPACE_FLAG)
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


; moves number in EAX:EDX to buffer specified by EDI
; stores the length of the number in eax
itoa:
    push    edi
    push    ebx       ;  save flags and argument pointer
    push    ecx

    push    byte 0      ; terminating null
    mov     ecx, 10

;get reversed string representation on the stack
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

 ; move string from the stack to output buffer and reverse it in the process
.reverse
    mov  bl, [esp]
    inc  esp
    mov  [edi], bl
    inc  edi
    cmp  bl, 0
    jne  .reverse

    lea     eax, [edi - 1]        ; number = [] ... [EDI - 1]
    add     esp, 3                ; after we pop EDI, [EDI] = beginning of the number => (old edi - 1) - edi = string length
    pop     ecx
    pop     ebx
    pop     edi
    sub     eax, edi
    ret