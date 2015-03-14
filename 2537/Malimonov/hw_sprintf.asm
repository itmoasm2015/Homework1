global hw_sprintf

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

.parse_number:
    xor edx, edx
    mov ebx, 10
    div ebx
    add edx, 48
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

.return:
    pop edi
    pop esi
    pop ebp
    pop ebx
    ret
