global hw_sprintf

%macro parse_flag 2
	cmp		[esi], byte %1
	jne		short %2
	or		al, bl
	inc		esi
	mov		ah, 1
	shl		bl, 1
%endmacro
section .text
	; int hw_unsigned_int_to_string(x, f)
	; return size of string representation unsigned int x
	; int f - mask of flags, use flags '+' and ' ' 
hw_unsigned_int_to_string:
	push	ebp
	mov		ebp, esp
	push	edi
	
	mov		edi, number
	mov		eax, [ebp + 8]

    mov ecx, 10
.loop:
    xor edx, edx
    div ecx
    add edx, '0'
    mov [edi], edx
    inc edi
    test eax, eax
    jnz .loop
	
	mov		eax, [ebp + 12]
	mov		ah, 1			;check plus
	test	al, ah			;
	jz		.no_plus		
	mov		[edi], byte '+'
	inc		edi
	jmp		.end
.no_plus
	shl		ah, 1			;check space
	test	al, ah				;
	jz		.end
	mov		[edi], byte ' '
	inc		edi
.end
	mov		eax, edi
	sub		eax, number
	pop		edi
	mov		esp, ebp
	pop		ebp
	ret


hw_sprintf:
	push	ebp
	mov		ebp, esp
	push	edi
	push	esi
	push	ebx
	
	; get first and second argument
	mov		edi, [ebp + 8]		;out
	mov		esi, [ebp + 12]		;format
	; check if format is empty
	cmp		[esi], byte 0
	je		.end	

.main_loop
	push	esi
	cmp		[esi], byte '%'
	jne		.just_print
	
	inc		esi
	
	cmp		[esi], byte 0
	je		.print_last_symbol

	;parse flags
	xor		al, al
.plus
	mov		ah, 0
	mov		bl, 1
	parse_flag '+', .space
.space
	parse_flag ' ', .minus
.minus
	parse_flag '-', .zero
.zero
	parse_flag '0', .end_parse_flag
.end_parse_flag
	test	ah, ah	
	jne		.plus
	push	eax		;save flags to stack

	;parse width

	xor		eax, eax
	mov		ecx, 10
.loop_width
	xor		ebx, ebx
	mov		bl, [esi]
	sub		bl, '0'
	cmp		bl, 9
	ja		.end_parse_width
	mul		ecx
	add		eax, ebx
	inc		esi
	jmp		.loop_width
.end_parse_width
	pop		ebx
	push	eax ; save width to stack
	push	ebx ; save flags to top of stack

	;parse size

	cmp		[esi], byte 'l'
	jne		.print_int
	inc		esi
	cmp		[esi], byte 'l'
	jne		.bad_sequence	
	inc		esi
	
	;print long long
	cmp		[esi], byte 'u'
	je		.print_unsigned_long_long
	cmp		[esi], byte '%'				;may be not need
	je		.just_print
	cmp		[esi], byte 'i'
	je		.print_signed_long_long
	cmp		[esi], byte 'd'
	je		.print_signed_long_long
	jmp		.bad_sequence	

.print_signed_long_long
	inc		esi
	;todo
.print_unsigned_long_long
	inc		esi
	;todo
	
.print_int
	cmp		[esi], byte 'u'
	je		.print_unsigned_int
	cmp		[esi], byte '%'
	je		.just_print
	cmp		[esi], byte 'i'
	je		.print_signed_int
	cmp		[esi], byte 'd'
	je		.print_signed_int
	jmp		.bad_sequence

.print_unsigned_int
	inc		esi
	;todo
.print_signed_int
	inc		esi
	;todo



.bad_sequence
	pop		ecx
	pop		ecx
	mov		ecx, esi
	pop		esi
	sub		ecx, esi
	cld
	rep		movsb
	jmp		.end_main_loop

.just_print
	cld
	movsb
.end_main_loop
	cmp		[esi], byte 0
	jne		.main_loop 
	jmp		.end

.print_last_symbol
	dec		esi
	mov		al, [esi]
	mov		[edi], al
	inc		edi
.end
	mov		[edi], byte 0

	pop		ebx
	pop		esi
	pop		edi
	mov		esp, ebp
	pop		ebp
	xor		eax, eax
	ret

section .bss
number	resb 20
