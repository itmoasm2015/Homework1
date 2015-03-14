global hw_sprintf

MINUS       equ '-'
ASCII_CONST equ 48

section .text

; void hw_swprintf(char* out, char const* format, ...)
hw_sprintf:
    push ebx
    push ebp
    push esi
    push edi

    mov edi, [esp + 32 - 12] ; out
    mov esi, [esp + 32 - 8] ; format
    lea ebp, [esp + 32 - 4] ; arguments

.process:
    mov al, byte [esi]
    cmp al, '%'
    je .format
    mov [edi], al
    inc edi

.check_null:
    test al, al
    je .return
    inc esi
    jmp .process

.format:
    mov eax, [ebp]
    xor ecx, ecx

    cmp eax, 0
    jl .print_minus

.parse_number:
    xor edx, edx
    mov ebx, 10
    div ebx
    add edx, ASCII_CONST
    push edx
    inc ecx
    test eax, eax
    jnz .parse_number


.reverse_get:
    pop eax
    mov [edi], eax
    inc edi
    dec ecx
    test ecx, ecx
    jnz .reverse_get
    jmp .check_null


.print_minus:
    mov edx, MINUS
    mov [edi], edx
    inc edi
    neg eax
    jmp .parse_number

.return:
    pop edi
    pop esi
    pop ebp
    pop ebx
    ret
