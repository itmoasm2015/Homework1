global hw_sprintf

section .text

	; saving stack pointer to function arguments
	mov edx, esp 	

	; put on stack callee-save registers
	push ebx
	push esi
	push edi
	push ebp


	






.exit
	; take from stack callee-save registers
	pop ebp
	pop edi
	pop esi
	pop ebx
