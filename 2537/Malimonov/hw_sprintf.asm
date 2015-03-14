global hw_sprintf

MINUS       equ '-'
ASCII_CONST equ 48

section .text

; void hw_swprintf(char* out, char const* format, ...)

hw_sprintf:                     ; save the status of the registers
    push ebx
    push ebp
    push esi
    push edi

    mov edi, [esp + 32 - 12]    ; out
    mov esi, [esp + 32 - 8]     ; format
    lea ebp, [esp + 32 - 4]     ; arguments

.process:                       ; process characters one at a time
    mov al, byte [esi]
    cmp al, '%'                 ; check if we met a special character
    je .format
    mov [edi], al               ; put the character into out
    inc edi

.check_null:                    ; check if we met the end of the string
    inc esi          
    test al, al                 
    je .return                  ; finish processing the string          
    jmp .process                ; process another character

.format:
    cmp al, 'd'                 ; if the number is decimal
    je .decimal

.decimal:
    inc esi
    mov eax, [ebp]              ; get a number to be put into out
    xor ecx, ecx                ; null out the counter of the number's length
    cmp eax, 0                  ; if the number is negative,
    jl .print_minus             ; print a minus and flip its sign

.unsigned:

.parse_number:                  ; the loop that
    xor edx, edx
    mov ebx, 10                 ; parses the number digit by digit
    div ebx
    add edx, ASCII_CONST        ; add the constant to turn the digit
    push edx                    ; into the corresponding character
    inc ecx                     ; and push it onto the stack
    test eax, eax               ; if the dividend still is not zero,
    jnz .parse_number           ; start over

.reverse_get:                   ; build the number from the stack
    pop eax
    mov [edi], eax              ; put a digit into out
    inc edi
    dec ecx                     ; reduce the number's length
    test ecx, ecx               ; if it is not zero
    jnz .reverse_get            ; keep getting digits
    jmp .check_null             ; else

.print_minus:                   ; quite obvious
    mov edx, MINUS
    mov [edi], edx              ; put a minus sign into out
    inc edi
    neg eax                     ; flip the number's sign
    jmp .parse_number           ; and start reading it onto the stack

.return:                        ; restore the status of the registers
    pop edi
    pop esi
    pop ebp
    pop ebx
    ret                         ; and finish
