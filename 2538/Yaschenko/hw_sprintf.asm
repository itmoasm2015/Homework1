section .text

FLAG_PLUS	equ	1 << 0
FLAG_SPACE	equ	1 << 1
FLAG_HYPHEN	equ	1 << 2
FLAG_ZERO	equ	1 << 3
FLAG_LL		equ	1 << 4	

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
        
        cmp byte [esi], '%'	; if current char is not escaping '%' sign
        jne .print_char		; just print it to *out

        xor ebx, ebx            ; else clear format flags
        je .parse               ; and parse format

.parse_flags:			; start parsing flags
        inc esi			; skip format char

        cmp byte [esi], '+'
        je .char_plus

        cmp byte [esi], ' '
        je .char_space

        cmp byte [esi], '-'
        je .char_hyphen

        cmp byte [esi], '0'
        je .char_zero

.parse_width:			; parse format width
	xor edx, edx		; edx stores 'width'
.parse_width_loop:
	cmp byte [esi], '0'	; if current char
	jl .parse_width_end	; is not digit
	cmp byte [esi], '9'	; skip
	jg .parse_width_end	; it

	lea edx, [edx + 4*edx]	; edx *= 5
	shl edx, 1		; edx *= 2

	xor eax, eax		
	mov al, byte [esi]	; edx += (current char) - '0'
	sub eax, '0'
	add edx, eax

	inc esi
	jmp .parse_width_loop
.parse_width_end:
	

.parse_size:			; parse length 'll' specificator
	cmp word [esi], 'll'
	jne .parse_type
	or ebx, FLAG_LL
	add esi, 2

.parse_type:
	cmp byte [esi], 'i'
	je .type_signed
	cmp byte [esi], 'd'
	je .type_signed
	cmp byte [esi], 'u'
	je .type_unsigned
	cmp byte [esi], '%'
	je .type_percent
	
.type_signed:

.type_unsigned:

.type_percent:
	jmp .print_char
	

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
	mov byte [edi], byte [esi]	; cur char is not special, so just
	inc edi				; print it to *out and inc both
	inc esi				; edi and esi pointers

        cmp byte [esi], '0'		; if current char from format is '\0'
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
