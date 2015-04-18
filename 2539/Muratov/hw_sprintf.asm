%define INT_INF 0xffffffff
%define PLUS_FLAG                   byte 1  ; '+'
%define SPACE_FLAG                  byte 2  ; ' '
%define LEFT_ALIGN_FLAG             byte 4  ; '-' 
%define FILL_WITH_ZEROES_FLAG       byte 8  ; '0'
%define LONG_LONG_FLAG              byte 16  ; 'll'
%define UNSIGNED_FLAG               byte 32  ; 'u' 

global hw_sprintf

section .bss
temp:           resb    30 ; buffer, to contain string representation of number
flags:          resb    1  ; contains flags, that was mentioned higher
width:          resd    1  ; minimal width of field, where should be written number
arg_cursor:     resd    1  ; points to the current hw_sprintf's argument in stack 
length:         resd    1  ; length of number which is stored in temp
sign:           resb    1  ; sign of number in temp. 0 - '-', 1 - '+'


section .text

;In all functions edi and esi registers points to out and format, so I don't pass them to my functions 
;All my functions are internal, except hw_sprintf


;void hw_sprintf(char* out, char const *format, ...);
hw_sprintf:
    push ebx
    push esi
    push edi
    mov edi, [esp + 16]
    mov esi, [esp + 20]
    lea eax, [esp + 24]
    mov [arg_cursor], eax
    
.main_loop: ;writes symbols from format to out, if finds '%', calls if_percent
    mov al, byte [esi]

    cmp al, '%'
    jne .not_percent 
    call if_percent
    jmp .main_loop
.not_percent

    mov byte [edi], al
    inc esi
    inc edi
    cmp al, 0
    jne .main_loop

    pop edi
    pop esi
    pop ebx
    ret

;Tries to process '%' and following symbols. If success, writes number to out, otherwise writes '%'. 
;Uses edi and esi registers from hw_sprintf to read/write symbols.
if_percent:
    push eax
    mov eax, esi 
    inc esi
    mov [flags], byte 0
    mov [width], dword 0
    
.percent_loop

    cmp byte [esi], '+'
    jne .not_plus
    
    or [flags], PLUS_FLAG
    inc esi

.not_plus:
    
    cmp byte [esi], ' '
    jne .not_space
    
    or [flags], SPACE_FLAG
    inc esi

.not_space:

    cmp byte [esi], '-'
    jne .not_align_left
    
    or [flags], LEFT_ALIGN_FLAG
    inc esi

.not_align_left:

    cmp byte [esi], '0'
    jne .not_fill_with_zero
    
    or [flags], FILL_WITH_ZEROES_FLAG
    inc esi

.not_fill_with_zero:

    cmp byte [esi], '+'
    je .percent_loop 
    cmp byte [esi], '-'
    je .percent_loop 
    cmp byte [esi], '0'
    je .percent_loop 
    cmp byte [esi], ' '
    je .percent_loop 
;end of .percent_loop

    cmp byte [esi], '1'
    jl .without_width
    cmp byte [esi], '9'
    jg .without_width
    call get_width

.without_width:

    cmp byte [esi], 'l'
    jne .not_ll
    inc esi
    cmp byte [esi], 'l'
    jne .if_error

    or [flags], LONG_LONG_FLAG
    inc esi

.not_ll:
    
    cmp byte [esi], 'u'
    jne .not_unsigned

    or [flags], UNSIGNED_FLAG 
    jmp .end_of_parsing

.not_unsigned:

    cmp byte [esi], 'i'
    je .end_of_parsing
    cmp byte [esi], 'd'
    je .end_of_parsing

    cmp byte [esi], '%'
    je .write_percent
    
    jmp .if_error

.end_of_parsing:
    inc esi 
    call write_number
    pop eax
    ret

.if_error:
    mov esi, eax
    
.write_percent:
    inc esi
    mov byte [edi], '%'
    inc edi
    pop eax
    ret

;writes number from temp to out
;edi should point to out 
write_from_temp_to_out:
    push esi
    push eax

    mov esi, temp
    
.loop2:
    mov al, byte [esi]
    
    cmp al, 0
    je .break_loop2
    
    mov byte [edi], al
    inc esi
    inc edi
    jmp .loop2
.break_loop2:

    pop eax
    pop esi
    ret


;function parses the number and writes it in variable width
;esi should point on beginning of the number
get_width:
    push eax
    push ebx
    push ecx
    push edx

    mov ch, 0
    mov ebx, 10

.next_digit
    
    inc ch
    mov cl, [esi]
    sub cl, '0'
    mov eax, [width]
    mul ebx
    mov [width], eax
    add [width], cl
    jo .break
    inc esi
    cmp byte [esi], '0'
    jl .break
    cmp byte [esi], '9'
    jg .break
    jmp .next_digit
.break

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret


;writes in out decimal representation of number according to variable flags and width
;number stores in [[arg_cursor]] 
write_number:   
    call number_to_string
    push eax
    ;eax - number of spaces/zeroes, should be written
    mov eax, [width]
    sub eax, [length]
    dec eax
    test [flags], SPACE_FLAG
    jnz .sign
    test [flags], PLUS_FLAG
    jnz .sign
    cmp [sign], byte 0
    je .sign

    inc eax

.sign
    
    cmp eax, 0
    jle .no_spaces_before
    test [flags], LEFT_ALIGN_FLAG
    jnz .no_spaces_before
    test [flags], FILL_WITH_ZEROES_FLAG
    jnz .no_spaces_before

.space_loop
    mov byte [edi], ' '
    inc edi
    dec eax
    jz .no_spaces_before
    jmp .space_loop

.no_spaces_before
    mov byte [edi], ' '
    test [flags], PLUS_FLAG
    jz .no_plus
    mov byte [edi], '+'
.no_plus
    cmp [sign], byte 0
    jne .no_minus
    mov byte [edi], '-'
.no_minus

    inc edi
    
    test [flags], SPACE_FLAG
    jnz .no_sign
    test [flags], PLUS_FLAG
    jnz .no_sign
    cmp [sign], byte 0
    je .no_sign

    dec edi

.no_sign 

    cmp eax, 0
    jle .no_zeroes_before
    test [flags], FILL_WITH_ZEROES_FLAG
    jz .no_zeroes_before
    test [flags], LEFT_ALIGN_FLAG
    jnz .no_zeroes_before

.zero_loop
    mov byte [edi], '0'
    inc edi
    dec eax
    jz .no_zeroes_before
    jmp .zero_loop

.no_zeroes_before

    call write_from_temp_to_out

    cmp eax, 0
    jle .no_spaces_after
    test [flags], LEFT_ALIGN_FLAG
    jz .no_spaces_after
    
.space_loop2
    mov byte [edi], ' '
    inc edi
    dec eax
    jz .no_spaces_after
    jmp .space_loop2

.no_spaces_after

    pop eax
    ret

;converts number, which stores in [[arg_cursor]], in string, and writes it in temp
number_to_string:
    push eax
    push ebx
    push ecx
    push edx
    test [flags], LONG_LONG_FLAG
    jz .not_long 
    mov eax, [arg_cursor]
    push dword [eax + 4]
    
    push dword [eax]
    
    test [flags], UNSIGNED_FLAG
    jnz .unsigned_l
    call signed_long
    jmp .signed_l
    .unsigned_l
    mov [sign], byte 1
    call unsigned_long
    .signed_l

    add esp, 8
    add [arg_cursor], dword 8
    jmp .long 
.not_long
    mov eax, [arg_cursor]
    push dword [eax]

    test [flags], UNSIGNED_FLAG
    jnz .unsigned_i
    call signed_int
    jmp .signed_i
    .unsigned_i
    mov [sign], byte 1
    call unsigned_int
    .signed_i
    
    add esp, 4
    add [arg_cursor], dword 4
.long

    mov eax, temp
    mov ecx, [length]
    lea ebx, [temp + ecx]
    mov [ebx], byte 0
    dec ebx

.rev_loop: ; reverses array temp 
    mov cl, [eax]
    mov ch, [ebx]
    mov [eax], ch
    mov [ebx], cl
    inc eax
    dec ebx
    cmp eax, ebx
    jl .rev_loop

    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

;void signed_int(int x)
;writes in temp string representation of x
signed_int:
    push eax
    push ebx
    xor ebx, ebx
    mov eax, [esp + 12]
    cmp eax, 0
    jge .positive
    not ebx
.positive
    cmp eax, 0
    push ebx
    push eax

    call signed_long
    add esp, 8
    pop ebx
    pop eax
    ret

;void unsigned_int(unsigned int x)
;writes in temp string representation of x
unsigned_int:
    push eax
    mov eax, [esp + 8]
    push dword 0
    push eax

    call unsigned_long
    add esp, 8
    pop eax
    ret


;void signed_long(long long x)
;writes in temp string representation of x
signed_long:
    push ebp
    mov ebp, esp
    push ebx

    mov ecx, [ebp + 8]
    mov edx, [ebp + 12]
    xor ebx, ebx
    mov [sign], byte 1
    cmp edx, 0
    jge .skip_sign
    test [flags], UNSIGNED_FLAG
    jnz .skip_sign
    mov [sign], byte 0
    not edx
    cmp ecx, 0
    jne .not_zero
    inc edx
.not_zero:
    neg ecx
.skip_sign:
    push edx
    push ecx

    call unsigned_long
    add esp, 8
    
    pop ebx
    mov esp, ebp
    pop ebp
    ret

;void unsigned_long(unsigned long long x)
;writes in temp string representation of x
unsigned_long:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push ebx

    mov edi, temp
    mov eax, [ebp + 8]
    mov edx, [ebp + 12]

    mov ecx, 10
    
.long_division:     
                
    mov ebx, eax
    mov eax, edx
    xor edx, edx
    div ecx         
    
    mov esi, eax
    mov eax, ebx
    div ecx      
    
    xchg eax, edx   
    
    add eax, '0'
    mov byte [edi], al
    inc edi
    
    mov eax, edx
    mov edx, esi
    
    test eax, INT_INF 
    jnz .long_division
    test edx, INT_INF 
    jnz .long_division

    mov eax, edi
    sub eax, temp
    mov [length], eax

    pop ebx
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret