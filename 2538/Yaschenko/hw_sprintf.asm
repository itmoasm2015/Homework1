section .text

FLAG_PLUS		equ	1 << 0
FLAG_SPACE		equ	1 << 1
FLAG_HYPHEN		equ	1 << 2
FLAG_ZERO		equ	1 << 3
FLAG_LL			equ	1 << 4
FLAG_SIGNED 		equ	1 << 5
FLAG_IS_NEGATIVE 	equ	1 << 6

%define setf(x) or ebx, x
%define testf(x) test ebx, x

; void hw_swprintf(char* out, char const* format, ...)
	global hw_sprintf

hw_sprintf:
				; _________________________________
				; subroutine prologue

				; save callee-saved registers
	push ebp
	mov ebp, esp

	push ebx
	push edi
	push esi
				; _________________________________
				; subroutine body

	mov edi, [ebp + 8]	; char* out (argument)
	mov esi, [ebp + 12]	; char const* format (argument)

	lea ecx, [ebp + 16]     ; pointer to 1st argument to format

.main_loop:                     ; iterates over chars in format
        
        cmp byte [esi], '%'	; if current char is '%' sign
	je .start_parse_flags		; parse flags, format, etc.

	cmp byte [esi], 0	; if current char from format is '\0'
        je .return		; then prepare to exit from function

	movsb			; else just print it to *out
	jmp .main_loop		; and continue with next char

.start_parse_flags:
	xor ebx, ebx		; reset flags
.parse_flags:
	push esi		; save '%' position (will return here if format string is invalid)
;;; TODO: remove esi from stack while debug
        inc esi			; skip '%' char

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

	imul edx, 10
	
	xor eax, eax		
	mov al, byte [esi]	; edx += (current char) - '0'
	sub eax, '0'
	add edx, eax

	inc esi
	jmp .parse_width_loop
.parse_width_end:
	push edx		; save format length on stack
	;; stack: <format length>4 | <last % location>4 | ...

.parse_size:			; parse length 'll' specificator
	cmp word [esi], 'll'
	jne .parse_type
	setf(FLAG_LL)
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
.type_invalid:			; if 'type' is not u|i|d|%
	add esp, 4		; then return to ((last '%' location) + 1)th
	pop esi			; char at *format and parse from that point
	inc esi			; (discarding <format width> on top of the stack)
	jmp .main_loop
	
.type_signed:
	setf(FLAG_SIGNED)
	jmp .prepare_output
	
.type_unsigned:
	jmp .prepare_output

.type_percent:			; 'type' is '%', so just print '%'
	add esp, 8		; discard <format width> and <last '%' location>
	movsb
	jmp .main_loop		; continue parsing

.prepare_output:	
	;; At this point 'flags', 'width', 'size' and 'type' are parsed
	;; for current '%' and appropriate flags (ebx) are set.
	;; Store current argument to output in EDX:EAX.
	inc esi			; skip 'type' char (u|i|d)
	testf(FLAG_LL)
	jnz .prepare_output_64

.prepare_output_32:
	xor edx, edx		; Since argument is 32bit number, EDX is set to zero.
	mov eax, [ecx]
	add dword ecx, 4	; Move pointer to next argument.

	testf(FLAG_SIGNED)
	jz .prepare_output_done

	cmp eax, 0
	jl .prepare_output_32_neg
	jmp .prepare_output_done

.prepare_output_64:
	mov eax, [ecx]		; Since argument is 64bit number, load it in EDX:EAX.
	mov edx, [ecx + 4]
	add dword ecx, 8	; Move pointer to next argument.

	testf(FLAG_SIGNED)
	jz .prepare_output_done

	cmp edx, 0
	jl .prepare_output_64_neg
	jmp .prepare_output_done

.prepare_output_32_neg:
	setf(FLAG_IS_NEGATIVE)
	neg eax
	jmp .prepare_output_done

.prepare_output_64_neg:
	setf(FLAG_IS_NEGATIVE)
	not edx			; negate 64bit number in EDX:EAX
	not eax			
	add eax, 1		; add 1 
	adc edx, 0		; and add CF is eax was 0xFFFFFFFF

.prepare_output_done:
	; testf(FLAG_ZERO)	; if has zero pad
	; jz .calc_padding
	; call output_first_char

.write_number:
	push edi
	mov edi, buf
	call int_to_str
	pop edi
	
	push ecx
	push esi
	mov ecx, eax
	mov esi, buf
.write_char:
	movsb
	loop .write_char
.write_number_done:
	pop esi
	pop ecx
	add esp, 8		; clear format length and last '%' pos
	jmp .main_loop		; continue main parse loop

.calc_padding:
	push edi
	mov edi, buf
	call int_to_str
	pop edi
	testf(FLAG_PLUS | FLAG_SPACE | FLAG_IS_NEGATIVE)
	jz .check_padding_need

.check_padding_need:
	cmp eax, [esp]			; Compare number length and 'format width'
	jge .pad_left_done


.pad_left_done:
	

;;; format flags
.char_plus:
        setf(FLAG_PLUS)
        jmp .parse_flags

.char_space:
        setf(FLAG_SPACE)
        jmp .parse_flags

.char_hyphen:
        setf(FLAG_HYPHEN)
        jmp .parse_flags

.char_zero:
        setf(FLAG_ZERO)
        jmp .parse_flags
;;; end format flags

					; ______________________________
					; subroutine epilogue

.return:
	add esp, 8
	mov byte [edi], 0
					; restore callee-saved registers
	pop esi
	pop edi
	pop ebx
	pop ebp
	ret

;; Puts string representation of number EDX:EAX to [EDI]
;; Return length of number in EAX 
int_to_str:	
	push ebx		; Preserve registers
	push ecx
	push edi

	push 0			; Chars counter
	mov ecx, 10		; Divisor
.div_loop:
	push eax		; Divide high 32bit of EDX:EAX by 10
	mov eax, edx
	xor edx, edx
	div ecx
	
	mov ebx, eax		; Save quotient in EBX
	
	pop eax			; Divide low 32 bit of EDX:EAX by 10
	div ecx
	xchg ebx, edx		; EDX:EAX is divided by ten, remainder in EBX

	add dword [esp], 1	; Increment chars counter
	add bl, '0'		; Turn remainder into char
	mov [edi], bl		; Put char to output
	inc edi

	cmp eax, 0		; If EDX:EAX != 0, continue division
	jne .div_loop

	pop eax
	cmp eax, 1		; Do not reverse since there is only one character
	jle .return
.reverse:
	push eax
	mov ebx, edi
	sub ebx, ecx		; EBX points to first char
	dec edi			; EDI points to last char
.reverse_loop:
	mov al, byte [ebx]	; DL stores first char to swap
	mov dl, byte [edi]	; AL stores last char to swap
	;; Perform XOR swap algorithm
	xor al, dl
	xor dl, al
	xor al, dl
	;; AL and DL are swapped now
	mov byte [ebx], al
	mov byte [edi], dl	; Put values back

	sub ecx, 2
	cmp ecx, 1		; If there is one (or zero) chars to swap left, we're done here.
	jle .return
	inc ebx			; Move ptr to first char
	dec edi			; Move ptr to last char
	jmp .reverse_loop
.reverse_done:
	pop eax
	
.return:
	pop edi			; Restore the rest of registers
	pop ecx
	pop ebx
	ret

;; Puts '-', '+' or ' ' (1st symbol of number) to [edi] and moves edi forward.
;; EBX should contain desired flags (specified in header).
;; Does not affect stack and other registers except edi. 
output_first_char:
	testf(FLAG_IS_NEGATIVE)
	jnz .put_minus
	
	testf(FLAG_PLUS)
	jnz .put_plus
	
	testf(FLAG_SPACE)
	jnz .put_space
	jmp .ret

.put_minus:
	mov byte [edi], '-'
	inc edi
	jmp .ret
.put_plus:
	mov byte [edi], '+'
	inc edi
	jmp .ret
.put_space:
	mov byte [edi], ' '
	inc edi
.ret:
	ret
	
	
section .bss
buf:	 resb 64		; buffer for string representation of current argument
