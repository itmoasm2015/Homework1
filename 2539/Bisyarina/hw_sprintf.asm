global hw_sprintf

section .bss

width:	resd 1			; variable to store current width if it is set
flag:	resd 1			; variable to store current flags of command sequence

section .text
;;; flags showing current command sequence state
SHOW_SIGN		equ 1		
SPACE_BEFORE		equ 1 << 1
LEFT_ALIGN		equ 1 << 2
ZERO_SYMB_COMPL	equ 1 << 3
WIDTH_SET		equ 1 << 4
IS_LONG_LONG		equ 1 << 5
IS_SIGNED		equ 1 << 6
IS_NEGATIVE		equ 1 << 7

hw_sprintf:
	mov eax, esp 		; saving STACK pointer to function arguments 

	push ebx 		; put on STACK callee-save registers
	push esi
	push edi
	push ebp
	
	add eax, 4
	mov edi, [eax] 	; put destination pointer address to EDI
	add eax, 4
	mov esi, [eax] 	; put pointer to format string beginning to ESI
	add eax, 4
	mov ebx, eax 		; put pointer to STACK arguments to EBX

;;; Main function that parses format string from ESI
;;; Processes it and puts result to EDI
.parse_format_char:
	mov al, [esi]
	inc esi
	cmp al, '%'
	jne .add_char_to_out

	dec esi		; if '%' found try to parse command sequence
	mov ebp, esi
	jmp .parse_comm_seq
.finish_parse_char: 		;checking if last processed symbol is not terminal
	cmp al, 0
	je .exit
	jmp .parse_format_char

.add_char_to_out: 		;Adds symbol from AL to address in EDI and increments EDI
	mov [edi], al
	inc edi
	jmp .finish_parse_char

;;; ESI points to the beginning of command sequence
;;; EBP points to current symbol of command sequence
;;; Function parses command sequence and adds result to out buffer
;;; If incorrect sequence symbol from ESI put to out buffer, ESI incremented
.parse_comm_seq:
	mov dword [flag], 0 	; initialising flags and width with 0
	mov dword [width], 0
.parse_flags:			;parsing flags
	inc ebp
	mov al, [ebp]
.check_sign:			; check for sign flag
	cmp al, '+'
	jne .check_space
	
	mov edx, [flag]
	or edx, SHOW_SIGN	
	mov [flag], edx

	jmp .parse_flags
.check_space: 			; check for space-before-number flag
	cmp al, ' '
	jne .check_right_align

	mov edx, [flag]
	or edx, SPACE_BEFORE
	mov [flag], edx

	jmp .parse_flags
.check_right_align:		; check for left alignment flag
	cmp al, '-'
	jne .check_zero_compl

	mov edx, [flag]
	or edx, LEFT_ALIGN
	mov [flag], edx

	jmp .parse_flags
.check_zero_compl: 		; check for completing with zeros flag
	cmp al, '0'
	jne .check_set_width

	mov edx, [flag]
	or edx, ZERO_SYMB_COMPL
	mov [flag], edx
	
	jmp .parse_flags
.check_set_width: 		; check if minimal width is set
	cmp al, '1'		; possible parsing of first number
	jl .check_set_ll
	cmp al, '9'
	jg .check_set_ll

	mov edx, [flag]
	or edx, WIDTH_SET
	mov [flag], edx

	sub al, '0'
	add [width], al

.check_set_not_first_num: 	; possible parsing second and further symbols
	inc ebp
	mov al, [ebp]
	
	cmp al, '0'
	jl .check_set_ll
	
	cmp al, '9'
	jg .check_set_ll
	
	sub al, '0'		; width is parsed by multiplying result of previous stage by 10
	push ecx		; and adding current figure
	push ebx
	push edx

	mov dword ebx, 10
	xor edx, edx
	xor ecx, ecx
	mov cl, al
	mov eax, [width]

	mul ebx
	add eax, ecx
	mov [width], eax
	mov eax, ecx

	pop edx
	pop ebx
	pop ecx
	
	jmp .check_set_not_first_num 

.check_set_ll:			; checking if a sequence of two 'l' begins in current symbol
	cmp al, 'l'
	jne .check_set_type
	
	inc ebp
	mov al, [ebp]
	
	cmp al, 'l'
	jne .incorrect_comm_seq	; if only one 'l' found the sequence is incorrect

	mov edx, [flag]
	or edx, IS_LONG_LONG
	mov [flag], edx

	inc ebp
	mov al, [ebp]
	jmp .check_set_type

.check_set_type:		; setting flags of type of a value
	cmp al, '%'
	je .process_percent_type 
	cmp al, 'u'
	je .put_out_value
	cmp al, 'i'
	je .set_signed
	cmp al, 'd'
	je .set_signed
	jmp .incorrect_comm_seq

.set_signed: 			; set IS_SIGNED flag state
	mov edx, [flag]
	or edx, IS_SIGNED
	mov [flag], edx
	jmp .put_out_value

.process_percent_type:		; puts to out buffer symbol '%' ignoring
	inc ebp
	mov esi, ebp
	jmp .add_char_to_out
;;; Function sets ESI after command sequence
;;; Puts value in the way specified by flag
.put_out_value:
	mov esi, ebp
	inc esi
	
	mov eax, [flag]		; determine if value is long long or not 
	and eax, IS_LONG_LONG
	cmp eax, 0
	jne .take_from_stack_long
.take_from_stack_int:			; process 32-bit number
	xor edx, edx			; set hi part of value with 0 and treat as long
	mov eax, [ebx]
	add ebx, 4

	mov ecx, [flag]
	and ecx, IS_SIGNED		; check if value is singed or not
	cmp ecx, 0
	je .ensure_no_sign_unsigned
	cmp eax, 0
	jnl .parse_num
	
	neg eax
	mov ecx, [flag]		; if signed and negative, save sign and negate
	or ecx, IS_NEGATIVE
	or ecx, SHOW_SIGN
	mov [flag], ecx

	jmp .parse_num
.take_from_stack_long:			; process 64-bit number
	mov eax, [ebx]
	add ebx, 4
	mov edx, [ebx]
	add ebx, 4

	mov ecx, [flag]
	and ecx, IS_SIGNED		; check if value is singed or not
	cmp ecx, 0
	je .ensure_no_sign_unsigned
	cmp edx, 0
	jnl .parse_num

	neg eax  			; if signed and negative, save sign and negate
	adc edx, 0
	neg edx
	mov ecx, [flag]
	or ecx, IS_NEGATIVE
	or ecx, SHOW_SIGN
	mov [flag], ecx
	jmp .parse_num

.ensure_no_sign_unsigned:		; check that SHOW_SIGN not set for unsigned
	mov ecx, [flag]		; fix if set
	and ecx, SHOW_SIGN
	cmp ecx, 0
	je .parse_num
	mov ecx, [flag]
	xor ecx, SHOW_SIGN
	mov [flag], ecx

;;; Takes value edx:eax and puts it's chars using FLAG to EDI
.parse_num:
	push esi
	push ebx
	push ebp
	
	mov esi, edx		; store the hi part(higher 32 bits of 64-bit value)
	mov ebx, eax		; store the lo part(lower 32 bits of 64-bit value) 
	xor ecx, ecx		; initialise counter of value string representetion size

.process_hi_part: 		; take modulus of dividing hi part of value 
	xor edx, edx
	mov eax, esi
	
	push ecx
	mov dword ecx, 10	; and store it in edx
	div ecx
	pop ecx
	mov esi, eax		; store result of devision in ESI

.process_lo_part: 		; take result of deividing of lo part with modulus of hi part
	mov eax, ebx
	push ecx
	mov dword ecx, 10
	div ecx
	pop ecx

.put_char:			; put char representing current last figure to stack
	mov ebx, eax

	add edx, '0'
	push edx
	inc ecx

	cmp esi, 0
	jne .process_hi_part
	cmp ebx, 0
	jne .process_hi_part

;; start processing minimal width
	mov eax, [flag]
	and eax, WIDTH_SET 	; check if minimal width is set
	cmp eax, 0
	je .put_sign

	mov ebx, [width]
	;; start to count the size of completion
	mov eax, SHOW_SIGN
	or eax, SPACE_BEFORE	; decrease if value has number or space
	and eax, [flag]
	cmp eax, 0

	je .set_align
	dec ebx

.set_align:
	cmp ecx, ebx
	jge .put_sign

	sub ebx, ecx		; subtract size of value
	mov [width], ebx	; save size of completion

	mov eax, [flag]
	and eax, LEFT_ALIGN	; check if completion is after or before value string
	cmp eax, 0

	jne .put_sign		; start putting put value if left alignment

	mov eax, [flag]
	and eax, ZERO_SYMB_COMPL ; determine symbol to complete with
	cmp eax, 0
	jne .put_zero
	mov dl, ' '
	jmp .put_compl
.put_zero:			; set completion symbol '0'
	mov dl, '0'
	mov eax, [flag]
	and eax, SHOW_SIGN 	; put out sign before completion if needed
	cmp eax, 0
	je .put_compl

	mov eax, [flag]
	xor eax, SHOW_SIGN	; fix not to put sign twice
	mov [flag], eax

	mov eax, [flag]
	and eax, IS_NEGATIVE	
	cmp eax, 0
	
	jne .put_zero_minus
	mov al, '+'
	mov [edi], al
	inc edi
	jmp .put_compl

.put_zero_minus:
	mov al, '-'
	mov [edi], al
	inc edi

.put_compl:			; put completion string to out buffer
	cmp ebx, 0
	jle .put_sign
	mov [edi], dl
	inc edi
	dec ebx
	jmp .put_compl

.save_width:
	mov dword [width], 0
.put_sign:			; put value sign to out buffer
	mov eax, [flag]
	and eax, SHOW_SIGN
	cmp eax, 0
	je .put_space
	
	mov eax, [flag]
	and eax, IS_NEGATIVE
	cmp eax, 0
	
	jne .put_minus
	mov al, '+'
	mov [edi], al
	inc edi
	jmp .put_out_num

.put_space:			; put space before value
	mov eax, [flag]
	and eax, SPACE_BEFORE
	cmp eax, 0
	je .put_out_num
	mov al, ' '
	mov [edi], al
	inc edi
	jmp .put_out_num

.put_minus:
	mov al, '-'
	mov [edi], al
	inc edi

.put_out_num:			; put out value by chars from stack
	cmp ecx, 0
	je .put_left_align
	pop edx
	mov [edi], dl
	inc edi
	dec ecx
	jmp .put_out_num

.put_left_align:		; put out completion in case of left alignment
	mov eax, [flag]
	and eax, WIDTH_SET
	cmp eax, 0
	
	mov eax, [flag]
	and eax, LEFT_ALIGN
	cmp eax, 0
	je .exit_putting_out

	mov ebx, [width]
	mov dl, ' '
.put_left_compl:		; put completion string to out buffer
	cmp ebx, 0
	jle .exit_putting_out
	mov [edi], dl
	inc edi
	dec ebx
	jmp .put_left_compl

.exit_putting_out:		; pop from stack saved regs from function putting put value
	pop ebp
	pop ebx
	pop esi
	jmp .parse_format_char
	
.incorrect_comm_seq:		; handling incorrect command sequence
	mov al, [esi]		; put first char out and increment pointer
	inc esi
	jmp .add_char_to_out

.exit:				; take from stack callee-save registers
	pop ebp
	pop edi
	pop esi
	pop ebx
