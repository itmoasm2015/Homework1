global hw_sprintf


section .bss
out_number: resb 40

section .text

SHOW_SIGN_FLAG equ 1<<1
SPACE_FLAG equ 1<<2
ALIGN_LEFT_FLAG equ 1<<3
ADDED_ZERO_FLAG equ 1<<4
LONG_SIZE_FLAG equ 1<<5
UNSIGNED_INT_FLAG equ 1<<6
IS_NEGATIVE_FLAG equ 1<<7

%define setf(f) or ecx, f
%define testf(f) test ecx, f

; void hw_sprintf(char* out, const char* format, ...)
hw_sprintf:
    push ebp
    mov ebp, esp
    push esi
    push edi

    mov edi, [ebp + 8] ; store ptr to out out_number
    mov esi, [ebp + 12] ; store format ptr
    lea ebx, [ebp + 16] ; store address of first argument

; loop for format
next_char:
    ; if currect char is %
    ; then parse directive
    cmp byte [esi], '%'
    je parse

    ; else just write symbol to out
    movsb 

    ; if it isn't terminated character than continue
    cmp byte [esi - 1], 0
    jne next_char

.return:
    pop edi
    pop esi
    mov esp, ebp
    pop ebp
    ret

; parsing directive
parse:
    ; save pointer to current format
    ; if there is problems while parse
    push esi
    ; STACK: pos_percent

    ; clear used registers
    xor ecx,ecx ; ecx - store flag register
    xor edx, edx 
    xor eax, eax

    ; skip char '%'
    inc esi

; parsing any flags
.parse_flag:
    lodsb

    ; sets flag if current character equals %1
    %macro macro_set_flag 2
        cmp al, %1
        jne %%end
        setf(%2)
        jmp .parse_flag
        %%end:
    %endmacro
        
    macro_set_flag '+', SHOW_SIGN_FLAG

    macro_set_flag ' ', SPACE_FLAG

    macro_set_flag '-', ALIGN_LEFT_FLAG

    macro_set_flag '0', ADDED_ZERO_FLAG

    jmp .parse_width

; get width and store it on stack
.parse_width:
    
    ; current symbol was loaded by parse_flag

    cmp al, '0'
    jb .parse_width_end

    cmp al, '9'
    ja .parse_width_end

    imul edx, 10
    sub eax, '0'
    add edx, eax

    lodsb
    jmp .parse_width

.parse_width_end:
    push edx
    ; STACK: width_length | percent_pos


; set flag if type is long long int
.parse_size:
    dec esi
    cmp word [esi], 'll'
    jne .parse_type

    setf(LONG_SIZE_FLAG)
    add esi, 2

; parsing type of argument
; by default it is signed
; set flag if it is unsigned
.parse_type:
    lodsb

    cmp al, 'u'
    je .set_unsigned_flag

    cmp al, 'i'
    je .output_parse

    cmp al, 'd'
    je .output_parse

    cmp al, '%'
    je .write_percent

    jmp .invalid_parse_format


; if got error while parsing directive
; move percent to out buffer
; and current position in format
.invalid_parse_format:
    add esp, 4
    mov esi, [esp]
    movsb
    mov [esp], esi
    jmp .complete_parse

; write percent if current directive is like %*%
.write_percent:
    add esp, 4
    stosb
    mov [esp], esi
    jmp .complete_parse

.set_unsigned_flag
    setf(UNSIGNED_INT_FLAG)
    jmp .output_parse

; succesful parse directive
; STACK: width | percent_pos
; now get argument
.output_parse:
    testf(LONG_SIZE_FLAG)
    jnz .get_number_64


; store number in eax
; edx = 0
.get_number_32:
    xor edx, edx
    mov eax, [ebx]
    add dword ebx, 4

    testf(UNSIGNED_INT_FLAG)
    jnz .get_number_end

    cmp eax, 0
    jl .negative_int32
    jmp .get_number_end

; if number < 0
; get absolute value and set flag
.negative_int32:
    setf(IS_NEGATIVE_FLAG)
    neg eax
    jmp .get_number_end

; store long long number in eax:edx
.get_number_64:
    mov eax, [ebx]
    mov edx, [ebx + 4]
    add dword ebx, 8

    testf(UNSIGNED_INT_FLAG)
    jnz .get_number_end

    cmp edx, 0
    jl .negative_int64
    jmp .get_number_end

; get absolute value of number
; and set flag
.negative_int64:
    setf(IS_NEGATIVE_FLAG)

    not eax
    not edx
    add eax, 1
    add edx, 0
    jmp .get_number_end

.get_number_end:
    call hw_itoa
    jmp .put_with_align

; finish stage
; write to out buffer with alignment
; STACK: min_width | percent_pos
; eax - number_length
.put_with_align:
    testf(IS_NEGATIVE_FLAG|SPACE_FLAG|SHOW_SIGN_FLAG)
    jz .put_con_aling
    inc eax

; edx -  count neccesary of symbols to min width
.put_con_aling:
    mov edx, [esp]
    sub edx, eax
    testf(ALIGN_LEFT_FLAG)
    jnz .put_left_aling

.put_right_align:
    testf(ADDED_ZERO_FLAG)
    jnz .put_right_zero

; align number to right side by spaces
.put_right_space:
    push ebx
    mov ebx, ' '
    call write_align
    pop ebx
    call write_sign_symbol
    call write_number_from_buf
    jmp .put_align_end

; align number to right side by zero
.put_right_zero:
    call write_sign_symbol
    push ebx
    mov ebx, '0'
    call write_align
    pop ebx
    call write_number_from_buf
    jmp .put_align_end

; align number to left side
.put_left_aling:
    call write_sign_symbol
    call write_number_from_buf
    push ebx
    mov ebx, ' '
    call write_align
    pop ebx
    jmp .put_align_end

; finish writing to out
; STACK: min_width | percent_pos
.put_align_end:
    add esp, 4
    ; save current pos in format on stack
    mov [esp], esi
    jmp .complete_parse
   
; STACK: current_pos
; restore current_pos
.complete_parse:
    pop esi
    jmp next_char

; function write symbols to out
; ebx - symb
; edx - count symbols to write
; edi - out
write_align:
    cmp edx, 0
    jle .write_align_end

.write_aling_loop:
        mov [edi], bl
        inc edi
        dec edx
        cmp edx, 0
        jg .write_aling_loop
        
.write_align_end:
        ret
    

; function write number from number buffer to out buffer
; out_number - number buffer
; edi - out buffer
write_number_from_buf:
    push esi
    mov esi, out_number

.write_number_loop:
    cmp byte [esi], 0
    je .write_number_end

    movsb
    jmp .write_number_loop

.write_number_end:
    pop esi
    ret


; write sign symbol before number
; if flag is setted
write_sign_symbol:
    %macro macro_write_symbol 2
        testf(%1)
        jz %%end
        mov byte [edi], %2
        inc edi
        jmp .write_sign_end
        %%end:
    %endmacro

    macro_write_symbol IS_NEGATIVE_FLAG, '-'
    macro_write_symbol SHOW_SIGN_FLAG, '+'
    macro_write_symbol SPACE_FLAG, ' '

.write_sign_end:
    ret

; function convert unsigned number to string represent
; input data:
; eax:edx - number
; out_number - buffet to write
; output data:
; out_number - string represent of number
; eax - length of number
hw_itoa:
    push edi
    push ebx
    push ecx
    push esi
    ; save terminated symbol on stack
    mov bl, 0
    dec esp
    mov [esp], bl


    mov edi, out_number
    mov ebx, 10
    xor ecx, ecx
    
; divide number by 10
; and store result on stack
.div_loop:
    ; number eax:edx divide by ebx
    mov esi, edx
    xchg eax, esi
    xor edx, edx
    div ebx 
    xchg eax, esi
    div ebx
    ; quitient in esi:eax, remainder in edx

    ; save remainder on stack
    add dl, '0'
    dec esp
    mov [esp], dl
    sub dl, '0'
    xchg edx, esi
    inc ecx

    cmp eax, 0
    jne .div_loop

 ; there is a reversed number on STACK
 ; write it to buffer
 .write_to_buf:
    mov dl, [esp]
    inc esp
    
    mov [edi], dl
    inc edi

    cmp dl, 0
    jne .write_to_buf

    mov eax, ecx

    pop esi
    pop ecx
    pop ebx
    pop edi
    ret
