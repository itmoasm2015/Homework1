section .text

global hw_sprintf

ON		equ	1 << 0

PLUS		equ	1 << 1
SPACE		equ	1 << 2
MINUS		equ	1 << 3
ZERO		equ	1 << 4

END1		equ	1 << 5

END2		equ	1 << 6

LL		equ	1 << 7

SIGN		equ	1 << 8

%macro setst 1
	test	eax, END1
	jnz	.wrong_percent
	or	eax, %1
%endmacro

hw_sprintf:
	push	ebp
	push	esi
	push	edi
	push	ebx

	lea	ebp, [esp + 28]
	mov	edx, [esi]
	test	edx, edx
	jz	.exit

	xor	eax, eax
	.loop:
		cmp	edx, '%'
		je	.percent
		test	eax, eax
		jz	.free_char
		cmp	edx, '+'
		je	.plus_char
		cmp	edx, ' '
		je	.space_char
		cmp	edx, '-'
		je	.minus_char
		cmp	edx, '0'
		je	.zero_char
		cmp	edx, 'l'
		je	.long_char
		cmp	edx, 'd'
		je	.int_out
		cmp	edx, 'u'
		je	.uint_out
		cmp	edx, '1'
		jb	.wrong_percent
		cmp	edx, '9'
		ja	.wrong_percent
		jmp	.read_width

	.endloop:
		inc	esi
		mov	edx, [esi]
		test	edx, edx
		jnz	.loop
	
.exit:
	xor	eax, eax
	mov	[edi], eax

	pop	ebx
	pop	edi
	pop	esi
	pop	ebp
	ret


	.percent:
		test	eax, ON
		jnz	.percent_out
		or	eax, ON
		mov	ecx, esi
		jmp	.endloop

	.free_char:
		mov	[edi], edx
		inc	edi
		jmp	.endloop
	
	.plus_char:
		setst	PLUS
		jmp	.endloop
	
	.space_char:
		setst	SPACE
		jmp	.endloop
	
	.minus_char:
		setst	MINUS
		test	eax, MINUS
		jnz	.ignore_zero
		jmp	.endloop
	
	.zero_char:
		setst	ZERO
		test	eax, MINUS
		jnz	.ignore_zero
		jmp	.endloop
	
	.ignore_zero:
		test	eax, ZERO
		jz	.endloop
		xor	eax, ZERO
		jmp	.endloop
	
	.read_width:
		test	eax, END1
		jnz	.wrong_percent
		or	eax, END1

		xor	ebx, ebx
		.width_loop:
			cmp	edx, '0'
			jb	.end_width_loop
			cmp	edx, '9'
			ja	.end_width_loop
			sub	edx, '0'
			imul	ebx, 10
			add	ebx, edx
			inc	esi
			mov	edx, [esi]
			jmp	.width_loop
		.end_width_loop:

		dec	esi
		ret
	
	.long_char:
		test	eax, END2
		jnz	.wrong_percent
		or	eax, END1
		or	eax, END2

		lea	edx, [esi + 1]
		mov	edx, [edx]
		cmp	edx, 'l'
		jne	.wrong_percent
		or	eax, LL
		ret
	
	.wrong_percent:
		xor	eax, eax
		.wrong_loop:
			mov	[edi], edx
			inc	edi
			inc	ecx
			mov	edx, [ecx]
			cmp	ecx, esi
			jne	.wrong_loop
		jmp	.endloop
	
	.percent_out:
		mov	[edi], edx
		inc	edi
		xor	eax, eax
		jmp	.endloop
	
	.int_out:
		or	eax, SIGN
	.uint_out:
		test	eax, LL
		jnz	out64
		jmp	out32

out32:
	jmp	hw_sprintf.endloop

out64:
	jmp	hw_sprintf.endloop
