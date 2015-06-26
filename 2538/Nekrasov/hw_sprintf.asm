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

NEGATIVE	equ	1 << 9

%macro setst 1
	test	eax, END1
	jnz	.wrong_percent
	or	eax, %1
%endmacro

%macro sout 1
	mov	[edi], %1
	inc	edi
	dec	esi
%endmacro

%macro padout 2
	xchg	ebx, ecx
	test	ecx, ecx
	jz	.end%2

	.loop%2:
		mov	[edi], %1
		inc	edi
		loop	.loop%2
	
	.end%2:
	xchg	ebx, ecx
%endmacro

hw_sprintf:
	push	ebp
	push	esi
	push	edi
	push	ebx

	mov	edi, [esp + 20]
	mov	esi, [esp + 24]
	lea	ebp, [esp + 28]
	xor	edx, edx
	mov	dl, byte [esi]
	test	edx, edx
	jz	.exit

	xor	eax, eax
	xor	ebx, ebx
	.loop:
		cmp	dl, '%'
		je	.percent
		test	eax, eax
		jz	.free_char
		cmp	dl, '+'
		je	.plus_char
		cmp	dl, ' '
		je	.space_char
		cmp	dl, '-'
		je	.minus_char
		cmp	dl, '0'
		je	.zero_char
		cmp	dl, 'l'
		je	.long_char
		cmp	dl, 'd'
		je	.int_out
		cmp	dl, 'i'
		je	.int_out
		cmp	dl, 'u'
		je	.uint_out
		cmp	dl, '1'
		jb	.wrong_percent
		cmp	dl, '9'
		ja	.wrong_percent
		jmp	.read_width

	.endloop:
		inc	esi
		mov	dl, byte [esi]
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
		mov	[edi], dl
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

		.width_loop:
			cmp	dl, '0'
			jb	.end_width_loop
			cmp	dl, '9'
			ja	.end_width_loop
			sub	dl, '0'
			imul	ebx, 10
			add	ebx, edx
			inc	esi
			mov	dl, byte [esi]
			jmp	.width_loop
		.end_width_loop:

		dec	esi
		mov	dl, byte [esi]
		jmp	.endloop
	
	.long_char:
		test	eax, END2
		jnz	.wrong_percent
		or	eax, END1
		or	eax, END2

		cmp	byte [esi], 'l'
		jne	.wrong_percent
		inc	esi
		or	eax, LL
		jmp	.endloop
	
	.wrong_percent:
		xor	eax, eax
		xor	ebx, ebx
		.wrong_loop:
			mov	dl, [ecx]
			mov	[edi], dl
			inc	edi
			inc	ecx
			cmp	ecx, esi
			jne	.wrong_loop
		mov	dl, [ecx]
		mov	[edi], dl
		dec	esi
		jmp	.endloop
	
	.percent_out:
		mov	[edi], dl
		inc	edi
		xor	eax, eax
		xor	ebx, ebx
		jmp	.endloop
	
	.int_out:
		or	eax, SIGN
	.uint_out:
		test	eax, LL
		jmp	number_out


number_out:
	push	esi
	push	ebx

	mov	ecx, eax

	test	ecx, LL
	jz	.check_negative1
	jmp	.check_negative2

.check_negative1:
	mov	eax, [ebp]
	test	ecx, SIGN
	jz	.length
	test	eax, eax
	jns	.length
	neg	eax
	mov	[ebp], eax
	or	ecx, NEGATIVE
	jmp	.length

.check_negative2:
	mov	edx, [ebp + 4]
	mov	eax, [ebp]
	test	ecx, SIGN
	jz	.length
	test	edx, edx
	jns	.length
	neg	edx
	neg	eax
	sbb	edx, 0
	mov	[ebp + 4], edx
	mov	[ebp], eax
	or	ecx, NEGATIVE

.length:
	xor	esi, esi
	test	ecx, LL
	jz	.length1
	jmp	.length2

.length1:
	test	eax, eax
	jz	.check_first
	.length_loop1:
		xor	edx, edx
		mov	ebx, 10
		div	ebx
		inc	esi
		test	eax, eax
		jnz	.length_loop1
	jmp	.check_first

.length2:
	cmp	edx, 10
	jb	.length_loop3

	push	eax
	mov	eax, edx
	.length_loop2:
		xor	edx, edx
		mov	ebx, 10
		div	ebx
		inc	esi
		cmp	eax, 10
		jnb	.length_loop2
	mov	edx, eax
	pop	eax

	test	eax, eax
	jz	.check_first
	.length_loop3:
		mov	ebx, 10
		div	ebx
		inc	esi
		xor	edx, edx
		test	eax, eax
		jnz	.length_loop3


.check_first:
	test	ecx, PLUS
	jnz	.add_first
	test	ecx, SPACE
	jnz	.add_first
	test	ecx, SIGN
	jz	.padding_width
	test	ecx, NEGATIVE
	jnz	.add_first
	jmp	.padding_width
	.add_first:
		inc	esi
		jmp	.padding_width

.padding_width:
	pop	ebx
	sub	ebx, esi
	test	ebx, ebx
	js	.overflowed
	jmp	.left_spaces
	.overflowed:
		xor	ebx, ebx
		jmp	.left_spaces

.left_spaces:
	test	ecx, MINUS
	jnz	.sign_out
	test	ecx, ZERO
	jnz	.sign_out
	mov	dl, ' '
	padout	dl, 0

.sign_out:
	test	ecx, NEGATIVE
	jnz	.minus_out
	test	ecx, PLUS
	jnz	.plus_out
	test	ecx, SPACE
	jnz	.space_out
	jmp	.zero_padding

	.minus_out:
		mov	dl, '-'
		sout	dl
		jmp	.zero_padding
	
	.plus_out:
		mov	dl, '+'
		sout	dl
		jmp	.zero_padding
	
	.space_out:
		mov	dl, ' '
		sout	dl
		jmp	.zero_padding

.zero_padding:
	test	ecx, ZERO
	jz	.number_out
	mov	dl, '0'
	padout	dl, 1

.number_out:
	lea	edi, [edi + esi]
	test	ecx, LL
	jz	.number_out1
	jmp	.number_out2

.number_out1:
	push	ebx
	mov	eax, [ebp]
	.number_loop1:
		dec	edi
		xor	edx, edx
		mov	ebx, 10
		div	ebx
		add	dl, '0'
		mov	[edi], dl
		test	eax, eax
		jnz	.number_loop1
	lea	edi, [edi + esi]
	pop	ebx
	jmp	.right_spaces

.number_out2:
	push	ebx
	mov	eax, [ebp + 4]
	cmp	eax, 10
	jb	.number_out_continue
	.number_loop2:
		dec	edi
		xor	edx, edx
		mov	ebx, 10
		div	ebx
		add	dl, '0'
		mov	[edi], dl
		cmp	eax, 10
		jnb	.number_loop2
.number_out_continue:
	mov	edx, eax
	mov	eax, [ebp]
	.number_loop3:
		dec	edi
		mov	ebx, 10
		div	ebx
		add	dl, '0'
		mov	[edi], dl
		xor	edx, edx
		test	eax, eax
		jnz	.number_loop3
	lea	edi, [edi + esi]
	pop	ebx

.right_spaces:
	test	ecx, MINUS
	jz	.end
	mov	dl, ' '
	padout	dl, 2

.end:
	pop	esi
	xor	eax, eax
	xor	ebx, ebx

	jmp	hw_sprintf.endloop


out64:
	jmp	hw_sprintf.endloop
