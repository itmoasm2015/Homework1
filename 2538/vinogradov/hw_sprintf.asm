section .text
global hw_sprintf

%assign flag_plus     1<<0	; +
%assign flag_space    1<<1	; ␣
%assign flag_hyphen   1<<2	; -
%assign flag_zero     1<<3	; 0
%assign length_ll     1<<4	; is the value 64-bit
%assign spec_unsigned 1<<5	; is the value unsigned
%assign neg_value     1<<6	; is the value negative
%define setflag(b) or ebx, b
%define testflag(b) test ebx, b

%macro longdiv 0
	;; divides edx:eax by ebx, stores the quotient in esi:eax and the remainder in edx
	;; division is based on http://www.df.lth.se/~john_e/gems/gem0033.html
	;; esi should be equal to edx in the beginning
	;; ebx=d
	;; esi=hi, edx=hi, eax=lo
	mov esi, edx		; esi=hi, edx=hi, eax=lo
	xchg eax, esi		; lo hi hi  
	xor edx, edx		; lo 0 hi
	div ebx			; lo hi%d hi/d
	xchg eax, esi		; hi/d hi%d lo
	div ebx			; hi/d (hi%d:lo)%d (hi%d:lo)/d
%endmacro

; void hw_sprintf(char *out, char const *format, ...)
hw_sprintf:
	push ebp
	mov ebp, esp

	;; save pointer to current value to output in [ebp-4]:
	sub esp, 4

	lea ecx, [ebp+16]
	mov [ebp-4], ecx		

	;; save registers
	push ebx                      
	push esi
	push edi

	mov edi, [ebp+8]	; *out
	mov esi, [ebp+12]	; *format

process_char:
	;; if the symbol is %, process it as a directive
	cmp byte [esi], '%'
	je process_directive		

	;; if it is not %, copy the symbol
	movsb

	;; if it was not 0, process next symbol, finish otherwise
	cmp byte [esi-1], 0
	jne process_char

	add esp, 4		; remove pointer to current value from stack

	;; restore registers
	pop edi
	pop esi
	pop ebx
	pop ebp

	ret

; process a directive
process_directive:
	;; STACK: ∅
	push esi		; save position of the beginning of the directive
	;; STACK: percent_pos
	add esi, 1		; skip '%' in format
	xor eax, eax		; clean place for symbols to be read
	xor ebx, ebx		; set all flags to zero by default


;; parse flags (0-␣+)
.parse_flags:
	lodsb			; read the symbol
	%macro parse_flag 2
		cmp al, %1
		jne %%end
		setflag(%2)
		jmp .parse_flags
		%%end:	
	%endmacro
	parse_flag '+', flag_plus
	parse_flag ' ', flag_space
	parse_flag '-', flag_hyphen
	parse_flag '0', flag_zero
.parse_flags_end:
	
;; parse width
.parse_width:
	xor edx, edx		; set width to zero by default
.parse_width_loop:
	;; finish if the symbol is not a digit
	cmp al, '0'
	jnge .parse_width_end
	cmp al, '9'
	jnle .parse_width_end

	;; add the digit to the width
	lea edx, [edx+4*edx]	; edx ← edx*5
	shl edx, 1		; edx ← edx*2
	sub eax, '0'
	add edx, eax

	lodsb			; read next symbol
	jmp .parse_width_loop
.parse_width_end:
	sub esi, 1		; unread last symbol
	push edx		; store width to stack
	;; STACK: width | percent_pos
	

;; parse length (32/64-bit)
.parse_length:
	cmp word [esi], 'll'
	jne .parse_length_end	; 32-bit, don't set the flag
	setflag(length_ll) 	; 64-bit, set the flag
	add esi, 2
.parse_length_end:

;; parse specification (idu%)
.parse_spec:
	lodsb			; read the symbol
	;; match the symbol:
	cmp al, 'i'
	je .parse_spec_signed
	cmp al, 'd'
	je .parse_spec_signed
	cmp al, 'u'
	je .parse_spec_unsigned
	cmp al, '%'
	je .parse_spec_percent
.parse_spec_invalid:
	;; none of the symbols matched, the specification is invalid
	;; STACK: width | percent_pos
	add esp, 4		; forget width
	;; STACK: percent_pos
	pop esi			; return to the position of %
	;; STACK: ∅
	movsb			; copy '%' to destination
	jmp process_char	; continue to the next character in format
.parse_spec_percent:
	;; '%' specification
	;; STACK: width | percent_pos
	add esp, 8		; forget width and percent_pos
	;; STACK: ∅
	stosb			; copy '%' to destination
	jmp process_char	; continue to the next character in format
.parse_spec_unsigned:	
	;; unsigned type, set the corresponding flag
	setflag(spec_unsigned)
.parse_spec_signed:
	;; signed type, do nothing (the flag is already 0 by default)

.parse_end:
	;; we have read all what we need
	;; STACK: width | percent_pos
	mov [esp+4], esi	; put position of the end of the directive instead of position of the beginning of directive
	;; STACK: width | directive_end_pos
	
;; get current value to be printed into stack and set neg_value flag if need to
;; absolute value is stored
;; 32-bit numbers are treated as 64-bit with zero high bits
.get_number_and_sign:
	;; STACK: width | directive_end_pos
	mov ecx, [ebp-4]	; get pointer to current value to output
	testflag(length_ll)
	jnz .get_number_64
.get_number_32:
	;; the number is 32 bit
	xor edx, edx		; set high bits to zero
	mov eax, [ecx]		; get the number
	add dword [ebp-4], 4	; move to the next value

	;; test if the number is negative:
	testflag(spec_unsigned)
	jnz .get_number_and_sign_end
	test eax, eax
	jge .get_number_and_sign_end
.get_number_32_negative:
	;; the 32-bit number is negative
	setflag(neg_value)	; set flag
	neg eax			; get absolute value
	jmp .get_number_and_sign_end

.get_number_64:
	;; the number is 64-bit
	mov eax, [ecx]		; get low bits
	mov edx, [ecx+4]	; get hight bits
	add dword [esp+8], 8	; move to the next value

	;; test if the number is negative:
	testflag(spec_unsigned)
	jnz .get_number_and_sign_end
	test edx, edx
	jge .get_number_and_sign_end
.get_number_64_negative:
	;; the 64-bit number is negative
	setflag(neg_value)	; set the flag

	;; get absolute value:
	not eax
	not edx
	add eax, 1
	adc edx, 0
.get_number_and_sign_end:
	;; STACK: width | directive_end_pos
	push ebx	   ; save flags to stack
	;; STACK: flags | width | directive_end_pos
	;; save the value to stack:
	push edx
	push eax
	;; STACK: value(8) | flags | width | directive_end_pos

;; get the actual width needed for this directive (number length + padding)
.calc_actual_width:
.calc_actual_width_plus:
	xor ecx, ecx
	testflag(flag_plus|flag_space|neg_value) ; test if there is going to be first symbol (sign or space before the number)
	jz .calc_actual_width_number
	mov ecx, 1		; 1 byte for the first symbol
.calc_actual_width_number:
	mov ebx, 10		; divisor = 10
	mov esi, edx
.calc_actual_width_big:
	;; the division result doesn't fit into eax
	cmp edx, 10
	jb .calc_actual_width_small
	longdiv			; esi:eax = edx:eax/10
	mov edx, esi
	add ecx, 1
	jmp .calc_actual_width_big
.calc_actual_width_small:
	;; the division result fits into eax
	div ebx
	add ecx, 1
	xor edx, edx
	test eax, eax
	jnz .calc_actual_width_small
.calc_actual_width_compare:
	;; compare necessary width with the width requested in the directive
	;; STACK: value(8) | flags | width | directive_end_pos
	cmp ecx, [esp+12]
	jle .calc_actual_width_has_pad
	jmp .calc_actual_width_no_pad
.calc_actual_width_has_pad:
	;; the requested width is bigger, add padding
	;; STACK: value(8) | flags | width | directive_end_pos
	mov edx, [esp+12]
	;; STACK: value(8) | flags | actual_width | directive_end_pos
	sub edx, ecx
	push edx
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	jmp .calc_actual_width_end
.calc_actual_width_no_pad:
	;; the requested width is smaller, no padding
	;; STACK: value(8) | flags | width | directive_end_pos
	mov [esp+12], ecx	; set actual width to be the width of the number
	;; STACK: value(8) | flags | actual_width | directive_end_pos
	push dword 0		; push pad_width
	;; STACK: pad_width | value(8) | flags | width | directive_end_pos
.calc_actual_width_end:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos

;; move to the rightmost position, as we are going to output right-to-left
.move_to_right:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	add edi, [esp+16]

;; put padding in the end if need to
.pad_right:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	mov ebx, [esp+12]     ; get the flags from stack
	test ebx, flag_hyphen ; test if the padding should be on the right
	jz .pad_right_end
.pad_right_loop_start:
	;; test if the pad width is not zero
	mov ebx, [esp]
	test ebx, ebx
	jz .pad_right_end
.pad_right_loop:
	sub edi, 1
	mov byte [edi], ' '
	dec ebx
	jnz .pad_right_loop
.pad_right_end:


;; output the number itself
.output:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	;; get the value to output from stack into edx:eax
	mov eax, [esp+4]	
	mov edx, [esp+8]
	mov ebx, 10		; divisor = 10
	mov esi, edx		; needed for longdiv

	;; division is simillar to .calc_actual_width_number
.output_big:
	cmp edx, 10
	jb .output_small

	longdiv

	;; output the digit
      	sub edi, 1
      	add dl, '0'
      	mov [edi], dl

	mov edx, esi		

	jmp .output_big
.output_small:
	div ebx

	;; output the digit
      	sub edi, 1
      	add dl, '0'
      	mov [edi], dl

	xor edx, edx
	test eax, eax
	jnz .output_small

;; output the first symbol (sign or space before the number) when pad symbol is ' '
.output_first:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	mov ebx, [esp+12]	; get flags from stack
	test ebx, flag_zero
	jnz .output_first_end	; don't output the first symbol if 0 flag is set
	call write_first_sym
.output_first_end:

;;; add padding to the beginning if need to
.pad_left:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	mov ebx, [esp+12]	; get flags from stack
	test ebx, flag_hyphen
	jnz .pad_left_end	; don't pad if the number is left-justified
	;; get padding symbol (' ' or '0') into eax:
	mov eax, ' '
	test ebx, flag_zero
	jz .pad_left_loop_start
	mov eax, '0'
.pad_left_loop_start:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	mov ebx, [esp]		; get padding width
	test ebx, ebx
	jz .pad_left_end	; don't pad if the padding width is zero
.pad_left_loop:
	;; 
	sub edi, 1
	mov [edi], al
	dec ebx
	jnz .pad_left_loop
.pad_left_end:

;; output the first symbol (sign or space before the number) when pad symbol is '0'
.output_first_begin:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	mov ebx, [esp+12]	; get flags from stack
	test ebx, flag_zero
	jz .output_first_begin_end ; output first symbol only if '0' flag is set
	call write_first_sym
.output_first_begin_end:


.end:
	;; STACK: pad_width | value(8) | flags | actual_width | directive_end_pos
	add edi, [esp+16]	; move to the end of the directive in *out
	add esp, 20		; clean stack
	;; STACK: directive_end_pos
	pop esi			; restore position in *format
	;; STACK: ∅
	jmp process_char	; continue to the next character

;; prints the first symbol (sign or space) if need to (if the value is negative or '+' or ' ' flag is set)
;; flags are expected to be in ebx register
write_first_sym:	
	%macro put_first_sym 2
		test ebx, %2
		jz %%skip
		mov byte [edi-1], %1
		sub edi, 1
		ret
		%%skip:	
	%endmacro
	put_first_sym '-', neg_value
	put_first_sym '+', flag_plus
	put_first_sym ' ', flag_space
	ret			; none of the flags matched, return

