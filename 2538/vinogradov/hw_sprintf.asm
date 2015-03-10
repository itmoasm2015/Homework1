%define setflag(b) or ebx, b
%define testflag(b) test ebx, b
%assign flag_plus     1<<0
%assign flag_space    1<<1
%assign flag_hyphen   1<<2
%assign flag_zero     1<<3
%assign length_ll     1<<4
%assign spec_unsigned 1<<5
%assign neg_value     1<<6	; is value to output negative

section .text

global hw_sprintf

; void hw_sprintf(char *out, char const *format, ...)
hw_sprintf:
	push ebp
	mov ebp, esp

	push ebx                      
	push esi
	push edi

	mov edi, [ebp+8]	; *out
	mov esi, [ebp+12]	; *format
	lea ecx, [ebp+16]	; pointer to current value to output
	push ecx

process_char:
	;; if the symbol is %, process it as a directive
	cmp byte [esi], '%'
	je process_directive		

	;; if it is not %, copy the symbol
	movsb

	;; if it was not 0, process next symbol
	cmp byte [esi-1], 0
	jne process_char

	add esp, 4		; forget value_pointer
	pop edi
	pop esi
	pop ebx
	pop ebp

	ret

; process a directive
process_directive:
	;; STACK: ∅
	push esi
	;; STACK: percent_pos
	add esi, 1		; skip %

;; ebx[3:0] ← flags 0-␣+
	xor eax, eax		; clean place for symbol
	xor ebx, ebx		; clear flags
.parse_flags:
	lodsb
.parse_flags_plus:
	cmp al, '+'
	jne .parse_flags_space
	setflag(flag_plus)
	jmp .parse_flags
.parse_flags_space:
	cmp al, ' '
	jne .parse_flags_hyphen
	setflag(flag_space)
	jmp .parse_flags
.parse_flags_hyphen:
	cmp al, '-'
	jne .parse_flags_zero
	setflag(flag_hyphen)
	jmp .parse_flags
.parse_flags_zero:
	cmp al, '0'
	jne .parse_flags_end
	setflag(flag_zero)
	jmp .parse_flags
.parse_flags_end:
	
.parse_width:
	xor edx, edx
.parse_width_loop:
	cmp al, '0'
	jnge .parse_width_end
	cmp al, '9'
	jnle .parse_width_end

	;; edx ← edx*10+(ah-'0')
	lea edx, [edx+4*edx]	; edx ← edx*5
	shl edx, 1
	sub eax, '0'
	add edx, eax

	lodsb
	jmp .parse_width_loop
.parse_width_end:
	sub esi, 1		; unread last symbol
	push edx		; store width to stack
	;; STACK: width | percent_pos
	

;; ebx[4] ← length_ll
.parse_length:
	cmp word [esi], 'll'
	jne .parse_spec
	setflag(length_ll)
	add esi, 2

;; ebx[5] ← spec_unsigned
.parse_spec:
	lodsb
	cmp byte al, 'i'
	je .parse_spec_signed
	cmp byte al, 'd'
	je .parse_spec_signed
	cmp byte al, 'u'
	je .parse_spec_unsigned
	
	;; invalid specification, roll back
.roll_back:
	;; STACK: width | percent_pos
	add esp, 4		; forget width
	;; STACK: percent_pos
	pop esi			; return to the position of %
	;; STACK: ∅
	mov byte [edi], '%'	; copy % to destination
	add esi, 1
	jmp process_char
	
.parse_spec_unsigned:	
	setflag(spec_unsigned)
.parse_spec_signed:

.parse_end:
	;; STACK: width | percent_pos
	mov [esp+4], esi
	;; STACK: width | directive_end_pos
	

.get_number_and_sign:
	;; STACK: width | directive_end_pos | VALUE_POINTER
	testflag(length_ll)
	jnz .get_number_64
.get_number_32:
	mov ecx, [esp+8]
	mov eax, [ecx]
	add dword [esp+8], 4
	cmp eax, 0	
	jge .get_number_32_positive
	testflag(spec_unsigned)
	jnz .get_number_32_positive
.get_number_32_negative:
	mov edx, 1<<31
	neg eax
	setflag(neg_value)
.get_number_32_positive:
	xor edx, edx
	jmp .get_number_and_sign_end
.get_number_64:
	mov ecx, [esp+8]
	mov eax, [ecx]
	mov edx, [ecx+4]
	add dword [esp+8], 8
	cmp edx, 0	
	jge .get_number_and_sign_end
	testflag(spec_unsigned)
	jnz .get_number_and_sign_end
.get_number_64_negative:
	;; get absolute value
	not eax
	not edx
	add eax, 1
	adc edx, 0
	setflag(neg_value)
.get_number_and_sign_end:
	;; STACK: width | directive_end_pos
	push ebx
	;; STACK: flags | width | directive_end_pos
	push eax
	;; STACK: value | flags | width | directive_end_pos

	;; TODO: length_ll
	;; testflag(length_ll)
	;; jz .output
	;; mov edx, [ecx]
	;; add ecx, 4



	;; get actual width
.calc_actual_width:
.calc_actual_width_plus:
	xor ecx, ecx
	testflag(flag_plus|flag_space|neg_value)
	jz .calc_actual_width_number
	mov ecx, 1		; place for sign or space
.calc_actual_width_number:
	mov esi, 10
.calc_actual_width_loop:
	xor edx, edx
	div esi
	add ecx, 1
	cmp eax, 0
	jne .calc_actual_width_loop
.calc_actual_width_compare:
	;; STACK: value | flags | width | directive_end_pos
	cmp ecx, [esp+8]
	jle .calc_actual_width_has_pad
	jmp .calc_actual_width_no_pad
.calc_actual_width_has_pad:
	;; STACK: value | flags | width | directive_end_pos
	mov edx, [esp+8]
	;; STACK: value | flags | actual_width | directive_end_pos
	sub edx, ecx
	push edx
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	jmp .calc_actual_width_end
.calc_actual_width_no_pad:
	;; STACK: value | flags | width | directive_end_pos
	mov [esp+8], ecx
	;; STACK: value | flags | actual_width | directive_end_pos
	push dword 0
	;; STACK: pad_width | value | flags | width | directive_end_pos
.calc_actual_width_end:
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos

.move_to_right:
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	add edi, [esp+12]	; start from the rightmost position

.pad_right:
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	mov ebx, [esp+8]
	test ebx, flag_hyphen
	jz .pad_right_end
.pad_right_loop_start:
	mov ebx, [esp]
	cmp ebx, 0
	je .pad_right_end
.pad_right_loop:
	sub edi, 1
	mov byte [edi], ' '
	dec ebx
	jnz .pad_right_loop
.pad_right_end:


.output:
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	mov eax, [esp+4]	; get the value to output

.write_sym:
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	xor edx, edx
	mov esi, 10
	div esi
	
	sub edi, 1
	add dl, '0'
	mov [edi], dl

	cmp eax, 0
	jne .write_sym

.output_first:
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	mov ebx, [esp+8]
	test ebx, flag_zero
	jnz .output_first_cont
	test ebx, flag_space|flag_plus|neg_value
	jz .output_first_cont
	call write_first_sym
.output_first_cont:

.pad_left:
	test ebx, flag_hyphen
	jnz .pad_left_end
	mov eax, ' '
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	mov ebx, [esp+8]
	test ebx, flag_zero
	jz .pad_left_loop_start
	mov eax, '0'
.pad_left_loop_start:
	mov ebx, [esp]
	cmp ebx, 0
	je .pad_left_end
.pad_left_loop:
	sub edi, 1
	mov [edi], al
	dec ebx
	jnz .pad_left_loop
.pad_left_end:

.output_first_begin:
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	mov ebx, [esp+8]
	test ebx, flag_zero
	jz .output_first_begin_cont
	test ebx, flag_space|flag_plus|neg_value
	jz .output_first_begin_cont
	call write_first_sym
.output_first_begin_cont:


.end:
	;; STACK: pad_width | value | flags | actual_width | directive_end_pos
	add edi, [esp+12]
	add esp, 16
	;; STACK: directive_end_pos
	pop esi
	;; STACK: ∅
	jmp process_char

write_first_sym:	
	test ebx, neg_value
	jz .plus
	mov byte [edi-1], '-'
	jmp .dec
.plus:
	test ebx, flag_plus
	jz .space
	mov byte [edi-1], '+'
	jmp .dec
.space:
	test ebx, flag_space
	jz .end
	mov byte [edi-1], ' '
.dec:
	sub edi, 1
.end:
	ret

write_pad:	
