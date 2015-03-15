global hw_sprintf

section .text

hw_sprintf:
	
;; saving STACK pointer to function arguments
	mov edx, esp 	

;; put on STACK callee-save registers
	push ebx
	push esi
	push edi
	push ebp

;; put destination pointer address to EDI
;; EDX - address to write next char of output
	mov edi, [edx]
	mov edx, edx + 4

;; put format string pointer to ESI`
;; ESI - pointer to current char of format string
	mov esi, [edx]
	mov edx, edx + 4

;; function that parses format string from pointer in ESI
.parse_format
;; finish if '\0000' found
	cmp [esi] 0
	je .exit
;; add current character to output if not command sequence 
	cmp [esi] '%'
	jne .add_in_to_out
;; start parsing command sequence if '%' found
	mov ebp, rsi
	inc ebp
	jump .parse_command_sequence

;; parses one command sequence beginning from EBP
.parse_command_sequence

	jmp put_out_value

.put_out_value

	jmp parse_format
	
;; puting all processed while parsing command sequence symbols to output
;; if sequence turned up incorrect
.invalid_comand_sequence
;; 
;;



;;; add current char of format string to output
;;; move pointers to next char
.add_in_to_out
	mov [edi], [esi] 	; move only byte TODO
	inc edi
	inc esi
	jump .parse_format

;; take from stack callee-save registers
.exit
	pop ebp
	pop edi
	pop esi
	pop ebx
