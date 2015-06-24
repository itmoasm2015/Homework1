section .text
global hw_sprintf

%assign plus 1<<0 ; +
%assign space 1<<1	; ' '
%assign left_align 1<<2 ; -
%assign zero_padding 1<<3 ; 0
%assign long_long 1<<4 ; long long
%assign unsigned 1<<5 ; unsigned value
%assign negative 1<<6 ; negative value
%define setflag(b) or ebx, b
%define testflag(b) test ebx, b

hw_sprintf:
	push ebp
	mov ebp, esp
	sub esp, 4 ; save pointer to current value to print in [ebp-4]
	lea ecx, [ebp+16]
	mov [ebp-4], ecx
	push ebx ; save registers               
	push esi
	push edi
	mov edi, [ebp+8] ; *out
	mov esi, [ebp+12] ; *format

get_next_symbol:
	cmp byte [esi], '%'
	je get_directive ; if symbol is % - get it as a directive		

	movsb ; else - copy the symbol

	cmp byte [esi-1], 0 ; if it is not 0, get next symbol, else - finish
	jne get_next_symbol

	add esp, 4 ; remove pointer to current value

restore_registers:
	pop edi
	pop esi
	pop ebx
	pop ebp

	ret

get_directive:
	push esi ; keep starting position
	add esi, 1 ; skip '%' in format
	xor eax, eax ; prepare place for getting symbols
	xor ebx, ebx ; set flags to zero

.get_flags:
	lodsb ; get symbol
	%macro get_flag 2
		cmp al, %1
		jne %%end
		setflag(%2)
		jmp .get_flags
		%%end:	
	%endmacro
	get_flag ' ', space
	get_flag '+', plus
	get_flag '0', zero_padding
	get_flag '-', left_align

.get_width:
	xor edx, edx ; set width to zero

.get_width_loop:
	; finish getting width if the symbol is not a digit
	cmp al, '0'
	jnge .get_width_end
	cmp al, '9'
	jnle .get_width_end

	; add digit to width
	lea edx, [edx+4*edx]
	shl edx, 1
	sub eax, '0'
	add edx, eax

	lodsb ; get next symbol
	jmp .get_width_loop

.get_width_end:
	sub esi, 1
	push edx
	

.get_length: ; 64 or 32 bit
	cmp word [esi], 'll'
	jne .get_length_end	; if 32 - then don't set flag
	setflag(long_long) 	; else - set
	add esi, 2
.get_length_end:

.get_format: ; d/i/u/%
	lodsb ; get symbol

	cmp al, 'd'
	je .get_signed
	cmp al, 'i'
	je .get_signed
	cmp al, 'u'
	je .get_unsigned
	cmp al, '%'
	je .get_percent

.invalid_format: ; if no one symbol matched
	add esp, 4
	pop esi	; return to the %-position
	movsb ; copy '%' to the adressee
	jmp get_next_symbol

.get_percent:
	add esp, 8
	stosb ; copy '%' to the adressee
	jmp get_next_symbol

.get_unsigned:
	setflag(unsigned)

.get_signed: ; do nothing

.get_end:
	mov [esp+4], esi ; place position of the end instead of starting position

.get_sign_and_number:
	mov ecx, [ebp-4] ; get pointer to current value to print
	testflag(long_long) ; test if number is long long
	jnz .get_64_bit_number

.get_32_bit_number: ; if number is 32-bit
	xor edx, edx
	mov eax, [ecx]
	add dword [ebp-4], 4

	testflag(unsigned) ; test if the number is negative
	jnz .get_sign_and_number_end
	test eax, eax
	jge .get_sign_and_number_end

.get_negative_32_number:
	setflag(negative)
	neg eax	; get abs
	jmp .get_sign_and_number_end

.get_64_bit_number:
	mov eax, [ecx]
	mov edx, [ecx+4]
	add dword [esp+8], 8

	testflag(unsigned) ; test if the number is negative
	jnz .get_sign_and_number_end
	test edx, edx
	jge .get_sign_and_number_end

.get_negative_64_bit_number:
	setflag(negative)

	; get abs:
	not eax
	not edx
	add eax, 1
	adc edx, 0

.get_sign_and_number_end:
	push ebx ; save flags
	push edx ; save value
	push eax

%macro longdiv 0 ; divides edx:eax by ebx, esi is equal to edx before devide
	mov esi, edx ; esi=hi, edx=hi, eax=lo
	xchg eax, esi ; lo hi hi  
	xor edx, edx ; lo 0 hi
	div ebx	; lo hi%d hi/d
	xchg eax, esi ; hi/d hi%d lo
	div ebx	; hi/d (hi%d:lo)%d (hi%d:lo)/d
%endmacro

.get_final_width: ; length + padding

.get_final_width_plus:
	xor ecx, ecx
	testflag(plus|space|negative)
	jz .get_final_width_number
	mov ecx, 1

.get_final_width_number:
	mov ebx, 10	; divider = 10
	mov esi, edx

.get_final_width_big: ; if result of division doesn't fit eax
	cmp edx, 10
	jb .get_final_width_small
	longdiv	; esi:eax = edx:eax/10
	mov edx, esi
	add ecx, 1
	jmp .get_final_width_big

.get_final_width_small: ; if result of division fits eax
	div ebx
	add ecx, 1
	xor edx, edx
	test eax, eax
	jnz .get_final_width_small

.get_final_width_compare: ; necessary width with requested
	cmp ecx, [esp+12]
	jle .get_final_width_has_padding
	jmp .get_final_width_no_padding

.get_final_width_has_padding: ; if the requested width is bigger than necessary - we should add padding
	mov edx, [esp+12]
	sub edx, ecx
	push edx
	jmp .get_final_width_end

.get_final_width_no_padding: ; else - shouldn't
	mov [esp+12], ecx; set final width
	push dword 0

.get_final_width_end:

.move_to_right: ; move to  position to print from right to left
	add edi, [esp+16]

.add_padding_right:
	mov ebx, [esp+12] ; get flags
	test ebx, left_align ; test if the padding should be on the right
	jz .add_padding_right_end

.add_padding_right_loop_start:
	mov ebx, [esp]
	test ebx, ebx
	jz .add_padding_right_end

.add_padding_right_loop:
	sub edi, 1
	mov byte [edi], ' '
	dec ebx
	jnz .add_padding_right_loop

.add_padding_right_end:


.print:
	mov eax, [esp+4]	
	mov edx, [esp+8]
	mov ebx, 10 ; divider = 10
	mov esi, edx

.print_big:
	cmp edx, 10
	jb .print_small
	longdiv

    sub edi, 1 ; print the digit
    add dl, '0'
    mov [edi], dl

	mov edx, esi		

	jmp .print_big

.print_small:
	div ebx

    sub edi, 1 ; print the digit
    add dl, '0'
    mov [edi], dl

	xor edx, edx
	test eax, eax
	jnz .print_small

.print_before_number: ; print symbol before number if padding symbol is ' '
	mov ebx, [esp+12]	; get flags
	test ebx, zero_padding ; test if ' ' is set
	jnz .print_before_number_end
	call print_first_symbol
.print_before_number_end:

.pad_left: ; add padding before number
	mov ebx, [esp+12] ; get flags
	test ebx, left_align
	jnz .pad_left_end
	mov eax, ' ' ; push padding symbol into eax:
	test ebx, zero_padding
	jz .pad_left_loop_start
	mov eax, '0'

.pad_left_loop_start:
	mov ebx, [esp] ; get padding width
	test ebx, ebx
	jz .pad_left_end

.pad_left_loop:
	sub edi, 1
	mov [edi], al
	dec ebx
	jnz .pad_left_loop

.pad_left_end:

.print_before_number_begin: 
	mov ebx, [esp+12]
	test ebx, zero_padding
	jz .print_before_number_begin_end
	call print_first_symbol
.print_before_number_begin_end:

.end:
	add edi, [esp+16] ; move to the end in *out
	add esp, 20 ; clean stack
	pop esi	; restore *format
	jmp get_next_symbol

; prints first symbol if ' ' flag is set or value is negative or '+'
print_first_symbol:	
	%macro push_first_symbol 2
		test ebx, %2
		jz %%skip
		mov byte [edi-1], %1
		sub edi, 1
		ret
		%%skip:	
	%endmacro

	push_first_symbol '-', negative
	push_first_symbol '+', plus
	push_first_symbol ' ', space
	ret	; if no one flag matched - return

