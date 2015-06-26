section .text

global hw_sprintf

; State contains information about a sequence, which is started with '%'
ON		equ	1 << 0				; a sequence is started or not

PLUS		equ	1 << 1				; show plus sign for a positive number
SPACE		equ	1 << 2				; show space sign for a positive number
MINUS		equ	1 << 3				; spaces fill free space right to the number
ZERO		equ	1 << 4				; zeroes fill free space

END1		equ	1 << 5				; we know all the flags	and the width

END2		equ	1 << 6				; we know all the flags ,the width and the size

LL		equ	1 << 7				; a number is long

SIGN		equ	1 << 8				; a number is signed

NEGATIVE	equ	1 << 9				; a number is negative

%macro setst 1						; set a flag %1
	test	eax, END1
	jnz	.wrong_sequence				; if we know all the flags, that is a wrong sequence
	or	eax, %1
%endmacro

%macro sout 1						; write out a sign %1
	mov	[edi], %1
	inc	edi
	dec	esi					; sign is no more in the length of the number
%endmacro

%macro padout 2						; write out a padding of symbols %1
	xchg	ebx, ecx				; changing ebx with ecx to use "loop"
	test	ecx, ecx
	jz	.end%2					; there is no padding

	.loop%2:
		mov	[edi], %1
		inc	edi
		loop	.loop%2
	
	.end%2:
	xchg	ebx, ecx
%endmacro

; first argument - buffer to write a result string
; second argument - buffer to read a format string
; next arguments - numbers to write instead right sequences for numbers
hw_sprintf:
	push	ebp
	push	esi
	push	edi
	push	ebx

	mov	edi, [esp + 20]				; edi <- result string
	mov	esi, [esp + 24]				; esi <- format string
	lea	ebp, [esp + 28]				; ebp <- pointer to numbers
	xor	edx, edx
	mov	dl, byte [esi]				; dl <- the next symbol
	test	edx, edx
	jz	.exit					; the format string is empty

	xor	eax, eax
	xor	ebx, ebx
	.loop:
		cmp	dl, '%'
		je	.percent
		test	eax, eax
		jz	.free_char			; a sequence has't been started
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
		jb	.wrong_sequence
		cmp	dl, '9'
		ja	.wrong_sequence
		jmp	.read_width

	.endloop:
		inc	esi
		mov	dl, byte [esi]			; dl <- the next symbol
		test	edx, edx
		jnz	.loop				; got a null symbol
	
	test	eax, ON
	jz	.exit
	dec	esi
	jmp	.wrong_sequence				; write out a wrong sequence in the end of the string
	
.exit:
	xor	eax, eax
	mov	[edi], eax				; finish the result string with a null symbol

	pop	ebx
	pop	edi
	pop	esi
	pop	ebp
	ret


	.percent:					; got a percent symbol in the format string
		test	eax, ON
		jnz	.percent_out			; that is the sequence for percent symbol
		or	eax, ON				; open a sequence
		mov	ecx, esi			; remember the first symbol of the sequence
		jmp	.endloop			; start of the sequence

	.free_char:					; a symbol outside of a sequence
		mov	[edi], dl			; just write it out
		inc	edi
		jmp	.endloop
	
	.plus_char:					; got a plus symbol in a sequence
		setst	PLUS
		jmp	.endloop
	
	.space_char:					; got a space symbol in a sequence
		setst	SPACE
		jmp	.endloop
	
	.minus_char:					; got a minus symbol in a sequence
		setst	MINUS
		test	eax, MINUS
		jnz	.ignore_zero			; a zero flag is not used with a minus flag
		jmp	.endloop
	
	.zero_char:					; got a zero symbol in a sequence
		setst	ZERO
		test	eax, MINUS
		jnz	.ignore_zero			; a zero flag is not used with a minus flag
		jmp	.endloop
	
	.ignore_zero:					; if set, delete the zero flag
		test	eax, ZERO
		jz	.endloop
		xor	eax, ZERO
		jmp	.endloop
	
	.read_width:					; read the width of the number
		test	eax, END1
		jnz	.wrong_sequence			; we already read the width
		or	eax, END1

		.width_loop:
			cmp	dl, '0'
			jb	.end_width_loop
			cmp	dl, '9'
			ja	.end_width_loop
			sub	dl, '0'			; dl is a digit symbol
			imul	ebx, 10
			add	ebx, edx
			inc	esi
			mov	dl, byte [esi]		; dl <- the next symbol
			jmp	.width_loop
		.end_width_loop:

		dec	esi
		mov	dl, byte [esi]
		jmp	.endloop
	
	.long_char:
		test	eax, END2
		jnz	.wrong_sequence			; we already read the size
		or	eax, END1
		or	eax, END2

		cmp	byte [esi + 1], 'l'
		jne	.wrong_sequence			; that is single "l" - the wrong sequence
		inc	esi
		or	eax, LL				; set the long number flag
		jmp	.endloop
	
	.wrong_sequence:
		xor	eax, eax			; reset the flags
		xor	ebx, ebx			; reset the width
		.wrong_loop:				; write out the wrong sequence
			mov	dl, [ecx]
			mov	[edi], dl
			inc	edi
			inc	ecx
			cmp	ecx, esi
			jne	.wrong_loop
		mov	dl, [ecx]
		mov	[edi], dl			; write the last symbol
		dec	esi
		jmp	.endloop
	
	.percent_out:					; write out a percent symbol
		mov	[edi], dl
		inc	edi
		xor	eax, eax
		xor	ebx, ebx
		jmp	.endloop
	
	.int_out:					; write out a signed number
		or	eax, SIGN
	.uint_out:					; write out an unsigned number
		jmp	number_out


number_out:
	push	esi
	push	ebx

	mov	ecx, eax

	test	ecx, LL
	jz	.check_negative1
	jmp	.check_negative2

.check_negative1:					; if signed and negative, get the module (for a short number)
	mov	eax, [ebp]
	test	ecx, SIGN
	jz	.length
	test	eax, eax
	jns	.length
	neg	eax
	mov	[ebp], eax
	or	ecx, NEGATIVE
	jmp	.length

.check_negative2:					; for a long number
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

.length:						; count the length of the number
	xor	esi, esi
	test	ecx, LL
	jz	.length1
	jmp	.length2

.length1:						; for a short number
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

.length2:						; for a long number
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


.check_first:						; check if a sign is needed
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

.padding_width:						; count the size of padding
	pop	ebx
	sub	ebx, esi
	test	ebx, ebx
	js	.overflowed
	jmp	.left_spaces
	.overflowed:
		xor	ebx, ebx
		jmp	.left_spaces

.left_spaces:						; pad with spaces left of the number
	test	ecx, MINUS
	jnz	.sign_out
	test	ecx, ZERO
	jnz	.sign_out
	mov	dl, ' '
	padout	dl, 0

.sign_out:						; write out a sign if needed
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

.zero_padding:						; pad with spaces left of the number
	test	ecx, ZERO
	jz	.number_out
	mov	dl, '0'
	padout	dl, 1

.number_out:						; write out the digits of the number
	lea	edi, [edi + esi]
	test	ecx, LL
	jz	.number_out1
	jmp	.number_out2

.number_out1:						; for a short number
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

.number_out2:						; for a long number
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

.right_spaces:						; pad with spaces right of the number
	test	ecx, MINUS
	jz	.increase
	mov	dl, ' '
	padout	dl, 2

.increase:						; get the next number
	test	ecx, LL
	jz	.increase1
	jmp	.increase2

.increase1:						; a short
	add	ebp, 4
	jmp	.end

.increase2:						; or a long
	add	ebp, 8

.end:
	pop	esi
	xor	eax, eax				; reset the flags
	xor	ebx, ebx				; reset the width

	jmp	hw_sprintf.endloop			; back to the main function
