section .text

FLAG_PLUS       equ         1 << 0
FLAG_SPACE      equ         1 << 1
FLAG_HYPHEN     equ         1 << 2
FLAG_ZERO       equ         1 << 3

; void hw_swprintf(char* out, char const* format, ...)
	global hw_sprintf

hw_sprintf:
				; __________________________________________________________________
				; subroutine prologue

				; save callee-saved registers
	push ebp
	mov ebp, esp

	push ebx
	push edi
	push esi
				; __________________________________________________________________
				; subroutine body

	mov edi, [ebp + 8]	; char* out (argument)
	mov esi, [ebp + 12]	; char const* format (argument)

	lea ebx, [ebp + 16]     ; the rest of arguments to format

.main_loop:                     ; iterates over chars in format
        xor edx, edx            
        mov dl, byte [esi]	; dl stores current character

        cmp dl, '%'		; if current char is not escaping '%' sign
        jne .print_char		; just print it to *out

        xor ebx, ebx            ; else clear format flags
        je .parse               ; and parse format

.parse_flags:			; start parsing flags
        inc esi			; skip format char
        mov dl, byte [esi]      ; get next format char

        cmp dl, '+'
        je .char_plus

        cmp dl, ' '
        je .char_space

        cmp dl, '-'
        je .char_hyphen

        cmp dl, '0'
        je .char_zero

	cmp dl, '1'		; current char < '1' (< '0' actually, see previous comparison)
	jl .print_char		; so it can't be 'width', 'size' or 'type' - just print it

	cmp dl, '9'
	jle .parse_width
	jmp .parse_

.parse_width:

.parse_size:

.parse_type:
	

.char_plus:
        or ebx, FLAG_PLUS
        jmp .parse_flags

.char_space:
        or ebx, FLAG_SPACE
        jmp .parse_flags

.char_hyphen:
        or ebx, FLAG_MINUS
        jmp .parse_flags

.char_zero:
        or ebx, FLAG_ZERO
        jmp .parse_flags

.print_char:
	mov byte [edi], dl		; cur char is not special, so just
	inc edi				; print it to *out and inc both
	inc esi				; edi and esi pointers

        cmp dl, 0x0			; if   current char from format is '\0'
        je .return			; then prepare to exit from function
        jmp .main_loop			; else continue main loop

					; __________________________________________________________________
					; subroutine epilogue

.return:
					; restore callee-saved registers
	pop esi
	pop edi
	pop ebx
	pop ebp
	ret

	
; section .bss                    ; unininitalized reserved space
