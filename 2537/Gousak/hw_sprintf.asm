global hw_sprintf

section .text
hw_sprintf:
	push ebp
    push esi
    push edi
    push ebx
    mov edi, [esp + 20]     ; edi = out
    mov esi, [esp + 24]     ; esi = format
    lea ebp, [esp + 28]     ; ebp = head(...)

.get_next:
	mov al, byte [esi]
	xor ah, ah
	mov [edi], al
	inc edi
	test al, al
	je .finally
	inc esi
	jmp .get_next

.finally:
	pop ebx
	pop edi
	pop esi
	pop ebp
	ret