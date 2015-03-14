global hw_sprintf

section .bss

width:	resd 1
flag:	resd 1

section .text

SHOW_SIGN		equ 1
SPACE_BEFORE		equ 1 << 1
RIGHT_ALIGN		equ 1 << 2
ZERO_SYMB_COMPL	equ 1 << 3
WIDTH_SET		equ 1 << 4
IS_LONG_LONG		equ 1 << 5
IS_SIGNED		equ 1 << 6
IS_NEGATIVE		equ 1 << 7

hw_sprintf:
	
;; saving STACK pointer to function arguments
	mov eax, esp

;; put on STACK callee-save registers
	push ebx
	push esi
	push edi
	push ebp
;; put destination pointer address to EDI
;; EDI - address to write next char of output
	add eax, 4
	mov edi, [eax]
	add eax, 4

;; put format string pointer to ESI
;; ESI - pointer to current char of format string
	mov esi, [eax]
	add eax, 4

;; put pointer to STACK arguments to EBX
;; EBX - pointer to current argument to process
	mov ebx, eax

;; Main function that parses format string from ESI by char
.parse_format_char:
	mov al, [esi]
	inc esi
	cmp al, '%'
	jne .add_char_to_out

	dec esi
	mov ebp, esi
	jmp .parse_comm_seq
.finish_parse_char:	
	cmp al, 0
	je .exit
	jmp .parse_format_char
;; Adds symbol from AL to address in EDI and increments EDI
;; Return to finishing symbol
.add_char_to_out:
	mov [edi], al
	inc edi
	jmp .finish_parse_char

;;; ESI points to the beginning of command sequence
;;; EBP points to symbol
.parse_comm_seq:
	xor al, al
	mov [flag], al
	mov [width], al
.parse_flags:
	inc ebp
	mov al, [ebp]
.check_sign:
	cmp al, '+'
	jne .check_space
	
	mov edx, [flag]
	or edx, SHOW_SIGN
	mov [flag], edx

	jmp .parse_flags
.check_space:
	cmp al, ' '
	jne .check_right_align

	mov edx, [flag]
	or edx, SPACE_BEFORE
	mov [flag], edx

	jmp .parse_flags
.check_right_align:
	cmp al, '-'
	jne .check_zero_compl

	mov edx, [flag]
	or edx, RIGHT_ALIGN
	mov [flag], edx

	jmp .parse_flags
.check_zero_compl:
	cmp al, '0'
	jne .check_set_width

	mov edx, [flag]
	or edx, ZERO_SYMB_COMPL
	mov [flag], edx
	
	jmp .parse_flags
.check_set_width:
	cmp al, '1'
	jl .check_set_ll
	cmp al, '9'
	jg .check_set_ll

	mov edx, [flag]
	or edx, WIDTH_SET
	mov [flag], edx

	sub al, '0'
	add [width], al

.check_set_not_first_num: 
	inc ebp
	mov al, [ebp]
	
	cmp al, '0'
	jl .check_set_ll
	
	cmp al, '9'
	jg .check_set_ll
	
	sub al, '0'
	push ecx
	push ebx

	xor ebx, ebx
	add ebx, 10
	xor ecx, ecx
	mov cl, al
	mov eax, [width]

	mul ebx
	add eax, eax
	mov [width], eax
	mov al, cl

	pop ebx
	pop ecx
	
	jmp .check_set_not_first_num 

.check_set_ll:
	cmp al, 'l'
	jne .check_set_type
	
	inc ebp
	mov al, [ebp]
	
	cmp al, 'l'
	jne .incorrect_comm_seq

	mov edx, [flag]
	or edx, IS_LONG_LONG
	mov [flag], edx

	inc ebp
	mov al, [ebp]
	jmp .check_set_type

.check_set_type:
	cmp al, '%'
	je .process_percent_type

	cmp al, 'u'
	je .put_out_value

	cmp al, 'i'
	je .set_signed

	cmp al, 'd'
	je .set_signed

	jmp .incorrect_comm_seq

.set_signed:
	mov edx, [flag]
	or edx, IS_SIGNED
	mov [flag], edx
	jmp .put_out_value

.process_percent_type:
	inc ebp
	mov esi, ebp
	jmp .add_char_to_out

;; Puts ESI to symbol after end of line of command sequence from EBP
;; Puts value from stack to edx:eax
.put_out_value:
	mov esi, ebp
	inc esi
	
	mov eax, [flag]
	and eax, IS_LONG_LONG
	cmp eax, 0
	jne .take_from_stack_long

	xor edx, edx
	mov eax, [ebx]
	add ebx, 4

	mov ecx, [flag]
	and ecx, IS_SIGNED
	cmp ecx, 0
	je .parse_num


	cmp eax, 0
	jnl .parse_num
	neg eax

	mov ecx, [flag]
	or ecx, IS_NEGATIVE
	mov [flag], ecx

	mov ecx, [flag]
	or ecx, SHOW_SIGN
	mov [flag], ecx

	jmp .parse_num
.take_from_stack_long:
	mov edx, [ebx]
	add ebx, 4
	mov eax, [ebx]
	add ebx, 4

	mov ecx, [flag]
	and ecx, IS_SIGNED
	cmp ecx, 0
	je .parse_num

	cmp edx, 0
	jnl .parse_num

	neg eax
	adc edx, 0
	neg edx
	
	mov ecx, [flag]
	or ecx, IS_NEGATIVE
	mov [flag], ecx

	mov ecx, [flag]
	or ecx, SHOW_SIGN
	mov [flag], ecx

;; Takes value edx:eax and puts it using FLAG to EDI
.parse_num:
	push esi
	push ebx
	push ebp
	
	mov esi, edx
	mov ebx, eax
	xor ecx, ecx

.process_hi_part:
	xor edx, edx
	mov eax, esi
	
	push ecx
	mov dword ecx, 10
	div ecx
	pop ecx

.process_lo_part:
	mov esi, eax
	
	mov eax, ebx

	push ecx
	mov dword ecx, 10
	div ecx
	pop ecx

.put_char:
	mov ebx, eax

	add edx, '0'
	push edx
	inc ecx

	cmp esi, 0
	jne .process_hi_part
	cmp ebx, 0
	jne .process_hi_part

.put_out_num:
	cmp ecx, 0
	je .exit_putting_out
	pop edx
	mov [edi], dl
	inc edi
	dec ecx
	jmp .put_out_num

.exit_putting_out:
	pop ebp
	pop ebx
	pop esi
	jmp .parse_comm_seq

.incorrect_comm_seq:
	mov al, [esi]
	inc esi
	jmp .add_char_to_out

;; take from stack callee-save registers
.exit:
	pop ebp
	pop edi
	pop esi
	pop ebx
