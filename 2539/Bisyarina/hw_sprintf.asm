global hw_sprintf

section .text

hw_sprintf:
	
;; saving STACK pointer to function arguments
	mov eax, esp 	

;; put on STACK callee-save registers
	push ebx
	push esi
	push edi
	push ebp

	add eax, 4
;; put destination pointer address to EDI
;; EDX - address to write next char of output
	mov edi, [eax]
	add eax, 4

;; put format string pointer to ESI
;; ESI - pointer to current char of format string
	mov esi, [eax]
	add eax, 4
;; put pointer to STACK arguments to EBX
;; EBX - pointer to current argument to process
	mov ebx, eax

	jmp .parse_format_char

.add_char_to_out:
	mov [edi], al
	inc edi
	jmp .finish_parse_char

;; take from stack callee-save registers
.parse_format_char:
	mov al, [esi]
	inc esi
	cmp al, '%'
	jne .add_char_to_out
.finish_parse_char:	
	cmp al, 0
	je .exit
	jmp .parse_format_char

.exit:
	pop ebp
	pop edi
	pop esi
	pop ebx
