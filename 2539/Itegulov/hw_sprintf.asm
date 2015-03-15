global hw_strlen    ; all functions are global for easy testing
global hw_itoa
global hw_ltoa
global hw_ultoa
global hw_format
global hw_sprintf

%define INT_INF 0xffffffff

%define FLAG_LONG   1   ; 'll' was found
%define FLAG_SIGNED 2   ; 'u' wan't found
%define FLAG_PLUS   4   ; '+' was found
%define FLAG_SPACE  8   ; ' ' was found
%define FLAG_ZERO   16  ; '0' was found
%define FLAG_MINUS  32  ; '-' was found
%define FLAG_NEG    64  ; if passed number is negative

section .bss
number  resb 21         ; used as a buffer, where we write next argument from 'hw_sprintf'
                        ; 21 is number's maximum length (19 + 1 (minus sign) + 1 (for '\0'))

section .text

; void hw_sprintf(char *out, char *in, ...)
; formats 'in' according to task
;
; implementation: contains big loop, which parses tokens
; and substitutes next argument if necessary. Uses 'hw_*toa'
; to write to 'number' and then passes it to 'hw_format' with
; parsed flags and width
hw_sprintf:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push ebx

    mov edi, [ebp + 8]
    mov esi, [ebp + 12]

    lea eax, [ebp + 16]             ; points to first argument

.loop:                              ; main loop, which parses string
    cmp byte [esi], '%'
    je .percent

.normal_format:                     ; ordinary character case (and invalid format case)
    mov dl, byte [esi]
    mov byte [edi], dl
    inc edi
    inc esi
    jmp .end_loop

.percent:                           ; '%' was found
    xor ebx, ebx                    ; it will contain flags
    xor ecx, ecx                    ; it will contain width
    xor edx, edx

    push esi                        ; store it to rollback from '.error'

.format_loop:                       ; loop, which parses flags one by one
    inc esi
    mov dl, [esi]

    cmp dl, '+'
    je .format_plus

    cmp dl, '-'
    je .format_minus

    cmp dl, ' '
    je .format_space

    cmp dl, '0'
    je .format_zero

    cmp dl, '0'
    jl .skip_width

    cmp dl, '9'
    jg .skip_width

.width_loop:                        ; loop, which parses width by "old = 10 * old + next_digit" method
    push eax
    push edx

    mov eax, ecx
    mov edx, 10
    mul edx

    pop edx

    sub dl, '0'
    add eax, edx
    mov ecx, eax
    pop eax


    inc esi
    mov dl, [esi]

    cmp dl, '0'
    jl .skip_width

    cmp dl, '9'
    jg .skip_width

    jmp .width_loop
    
.skip_width:
    cmp dl, 'l'
    jne .skip_size
    
    inc esi
    mov dl, [esi]
    cmp dl, 'l'
    jne .error                      ; just one 'l' is something strange

    inc esi                         
    mov dl, [esi]                   

    or ebx, FLAG_LONG

.skip_size:
    cmp dl, '%'
    jne .not_percent

    mov byte [edi], '%'             ; found '%*%' and we just need to output '%'
    inc edi
    inc esi
    jmp .loop

.not_percent:
    push ecx

    cmp dl, 'u'                     ; it's a dull cases analysis to solve which 'hw_*toa'
    jne .signed                     ; to use. It looks big, but obvious in fact
    inc esi

    test ebx, FLAG_LONG
    jnz .u_long

    push eax
    
    push number
    push dword 0
    push dword [eax]
    call hw_ultoa
    add esp, 12

    pop eax

    add eax, 4
    jmp .wrote_number
.u_long:
    push eax

    push number
    push dword [eax + 4]
    push dword [eax]
    call hw_ultoa
    add esp, 12
    
    pop eax

    add eax, 8
    jmp .wrote_number

.signed:
    or ebx, FLAG_SIGNED

    cmp dl, 'i'
    je .correct_signed
    cmp dl, 'd'
    je .correct_signed
    
    pop ecx

.error:
    pop esi
    jmp .normal_format

.correct_signed:
    inc esi
    test ebx, FLAG_LONG
    jnz .long

    push eax

    push number
    push dword [eax]
    call hw_itoa
    add esp, 8

    pop eax

    add eax, 4
    jmp .wrote_number

.long:
    push eax

    push number
    push dword [eax + 4]
    push dword [eax]
    call hw_ltoa
    add esp, 12

    pop eax

    add eax, 8
    jmp .wrote_number

.wrote_number:
    pop ecx                         ; at this moment we wrote number represntation to            
    push ecx                        ; 'number' and parsed all flags and width
    push eax                        ; so we just restore them

    push ecx
    push ebx
    push number
    push edi
    call hw_format                  ; and call hw_format to all job for us
    add esp, 16

    pop eax
    pop ecx

    jmp .skip_to_zero
    
.format_plus:
    or ebx, FLAG_PLUS
    jmp .format_loop

.format_minus:
    or ebx, FLAG_MINUS
    jmp .format_loop

.format_space:
    or ebx, FLAG_SPACE
    jmp .format_loop

.format_zero:
    or ebx, FLAG_ZERO
    jmp .format_loop

.skip_to_zero:
    push eax

    mov ecx, 0xffffffff             ; we need to skip characters until find '\0'
    xor eax, eax
    cld
    repne scasb
    dec edi

    pop eax
    jmp .loop

.end_loop:
    test byte [esi - 1], 0xff
    jnz .loop

    pop ebx
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret
    
    

; void hw_format(char *out, char *in, int flags, int width) 
; formats 'in' according to 'flags' and 'width' and writes
; result to 'out'
; 
; implementation: just contains dull case analysis
hw_format:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push ebx

    mov edi, [ebp + 8]
    mov esi, [ebp + 12]
    mov ebx, [ebp + 16]
    mov ecx, [ebp + 20]
    
    test ebx, FLAG_MINUS
    jz .skip_remove_zero

    and ebx, ~FLAG_ZERO         ; ignore zero flag, if there is minus flag

.skip_remove_zero:
    cmp byte [esi], '-'         ; sets negative flag, if necessary
                                ; we need this to know number's actual length
    jne .not_negative
    
    or ebx, FLAG_NEG
    inc esi
    
.not_negative:
    push ecx
    
    push esi
    call hw_strlen
    add esp, 4
    mov edx, eax                ; now edx contains number's length

    pop ecx

    test ebx, FLAG_PLUS | FLAG_SPACE | FLAG_NEG
    jz .no_additional_char      ; we need to increase number length if necessary
    
    inc edx                 

.no_additional_char:
    cmp edx, ecx
    jl .skip_extend_width
    
    mov ecx, edx                ; adjust width to number's length if it's lesser

.skip_extend_width:
    ; edx - full length of number
    ; ecx - extended width

    sub ecx, edx                ; now we have indent's length in ecx

    test ebx, FLAG_MINUS | FLAG_ZERO
    jnz .skip_left_indent
    
    mov al, ' '
    rep stosb

.skip_left_indent:              ; here we write some additional prefix char if need to
    test ebx, FLAG_NEG
    jz .positive
    
    mov byte [edi], '-'
    inc edi
    dec edx
    jmp .wrote_sign

.positive:
    test ebx, FLAG_PLUS
    jz .no_plus

    mov byte [edi], '+'
    inc edi
    dec edx
    jmp .wrote_sign

.no_plus:
    test ebx, FLAG_SPACE
    jz .wrote_sign

    mov byte [edi], ' '
    inc edi
    dec edx

.wrote_sign:
    test ebx, FLAG_ZERO
    jz .skip_zeros

    mov al, '0'
    rep stosb

.skip_zeros:
    xchg ecx, edx               ; now ecx contains number's length
    rep movsb
    mov ecx, edx                ; and we swap them back, but we don't care
                                ; about number's length anymore
    
    test ebx, FLAG_MINUS
    jz .end

    mov al, ' '
    rep stosb

.end:
    mov byte [edi], 0

    pop ebx
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret

; int hw_strlen(const char *)
; returns string's length 
hw_strlen:
    push ebp
    mov ebp, esp
    push edi
    mov edi, [ebp + 8]
    
    mov edx, edi
    xor eax, eax
    
    mov ecx, INT_INF 
    
    cld
    repnz scasb         
    
    sub edi, edx            ; length can be calculated by substracting begining address from ending address
    mov eax, edi    
    dec eax                 ; minus one, because scasb made one extra operation

    pop edi
    mov esp, ebp
    pop ebp
    ret

; int hw_uitoa(unsigned long long, char *)
; writes string representation of unsigned long long
; returns length of output string
hw_ultoa:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push ebx

    mov eax, [ebp + 8]
    mov edx, [ebp + 12]
    mov edi, [ebp + 16]
    mov ecx, 10

.long_division:     ; loop for division of long numbers
                    ; current number - (edx:eax)
    mov ebx, eax
    
    mov eax, edx
    xor edx, edx
    div ecx         ; divide (0:high_half) by 10
    
    mov esi, eax
    mov eax, ebx
    div ecx         ; divide (high_half_reminder:low_half) by 10
    
    xchg eax, edx   
    
    add eax, '0'    ; store remainder
    stosb
    
    mov eax, edx    ; move halves to their places
    mov edx, esi
    
    test eax, INT_INF 
    jnz .long_division
    test edx, INT_INF 
    jnz .long_division

    mov [edi], word 0
    dec edi

    mov eax, [ebp + 16]
    mov esi, edi
.string_reverse: 
    mov dl, [edi]
    mov cl, [eax]
    mov [edi], cl
    mov [eax], dl
    inc eax
    dec edi
    cmp eax, edi
    jl .string_reverse
    
    mov eax, esi
    sub eax, [ebp + 16]
    inc eax

    pop ebx
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret

; int hw_litoa(long long, char *)
; writes string representation of signed long long
; 
; implementation: it writes sign if necessary
; then just calls hw_ultoa 
;
; returns length of output string
hw_ltoa:
    push ebp
    mov ebp, esp
    push edi
    push ebx

    mov ecx, [ebp + 8]
    mov edx, [ebp + 12]
    mov edi, [ebp + 16]
    xor ebx, ebx

    cmp edx, 0
    jge .skip_sign
    not edx
    cmp ecx, 0
    jne .not_zero
    inc edx
.not_zero:
    neg ecx
    mov al, '-'
    stosb
.skip_sign:
    push edi
    push edx
    push ecx
    call hw_ultoa
    add esp, 12
    
    pop ebx
    pop edi
    mov esp, ebp
    pop ebp
    ret


; int hw_itoa(int, char *)
; writes string representation of signed int 
; 
; implementation: it writes sign if necessary
; and then just calls hw_ultoa
;
; returns length of output string
hw_itoa:
    push ebp
    mov ebp, esp
    push edi
    push ebx
    
    mov edx, [ebp + 8]      
    mov edi, [ebp + 12]    
    xor ebx, ebx

    cmp edx, 0
    jge .skip_sign
    
    mov al, '-'
    stosb
    neg edx
    inc ebx

.skip_sign:
    push edi
    push dword 0
    push edx
    call hw_ultoa
    add esp, 12
    add eax, ebx

    pop ebx
    pop edi
    mov esp, ebp
    pop ebp
    ret
