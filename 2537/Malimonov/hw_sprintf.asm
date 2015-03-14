global hw_sprintf

section .text

; void hw_swprintf(char* out, char const* format, ...)
hw_sprintf:
    
    push ebx
    push ebp
    push esi
    push edi

    mov edi, [esp + 20] ; out
    mov esi, [esp + 24] ; format
    mov ebp, [esp + 28] ; flags

    jmp .process

.process:
    
    mov al, byte [esi]
    xor ah, ah
    mov [edi], al
    inc edi
    test al, al
    je .return
    inc esi
    jmp .process

.return:
    
    pop edi
    pop esi
    pop ebp
    pop ebx
    ret