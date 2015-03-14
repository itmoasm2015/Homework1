global hw_sprintf

%macro parse_flag 3 
	cmp		[esi], byte %1
	jne		short %2
	or		al, %3
	inc		esi
	mov		ah, 1
%endmacro

%macro get_arg 1
	mov		%1, [ecx]
	add		ecx, 4
%endmacro

%macro copy 0
	push	edx
	push	ecx
	push	ebx
	
	mov		edx, number
	add		edx, eax
	dec		edx
	mov		ecx, eax

%%lp: mov		bl, [edx]
	mov		[edi], bl
	dec		edx
	inc		edi
	loop	%%lp

	pop		ebx
	pop		ecx
	pop		edx
%endmacro

%macro check_flag 3
	test	al, %1 			
	jz		%3		
	mov		[edi], byte %2
	inc		edi
%endmacro


section .text
	; int hw_unsigned_int_to_string(x, f)
	; return size of string representation unsigned int x
	; int f - mask of flags, use flags '+' and ' ' 
hw_unsigned_int_to_string:
	push	ebp
	mov		ebp, esp
	push	edi
	push	ecx
	
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
	check_flag minus_cast_flag, '-', .no_cast_minus
	jmp		.end
.no_cast_minus
	check_flag plus_flag, '+', .no_plus
	jmp		.end
.no_plus
	check_flag space_flag, ' ', .end
.end
	mov		eax, edi
	sub		eax, number
	
	pop		ecx
	pop		edi
	mov		esp, ebp
	pop		ebp
	ret



; hw_luitoa(unsigned long long, char *)
; writes string representation of the first @param to second @param
; return length of string representation of the first @param
hw_unsigned_long_long_to_string
    push	ebp
    mov		ebp, esp
    push	edi
	push	esi
    push	ecx

    mov		eax, [ebp + 8]
    mov		edx, [ebp + 12]
	mov		edi, number
    mov		ecx, 10

.loop: ; current number - (edx:eax)
        ; edx - high_half
        ; eax - low_half
    mov		ebx, eax	;save low_half to ebx
    mov		eax, edx 
    xor		edx, edx	
    div		ecx         ; div (0:high_half) by 10
    mov		esi, eax
    mov		eax, ebx
    div		ecx         ; div (high_half_rem:low_half) by 10
    add		edx, '0'
    mov		[edi], edx
    inc		edi
    mov		edx, esi
    test	eax, eax
    jne		.loop
    test	edx, edx
    jne		.loop

	mov		eax, [ebp + 16]
	
	check_flag minus_cast_flag, '-', .no_cast_minus
	jmp		.end
.no_cast_minus
	check_flag plus_flag, '+', .no_plus
	jmp		.end
.no_plus
	check_flag space_flag, ' ', .end
.end

	mov		eax, edi
	sub		eax, number
	
    pop		ecx
	pop		esi
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
	lea		ecx, [ebp + 16]		;args
	push	ecx
	
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
	parse_flag '+', .space, plus_flag
.space
	parse_flag ' ', .minus, space_flag
.minus
	parse_flag '-', .zero, minus_flag
.zero
	parse_flag '0', .end_parse_flag, zero_flag
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
	mov		ecx, [ebp - 16]
	get_arg eax
	get_arg edx
	mov		[ebp - 16], ecx
	cmp		edx, 0
	jge		.print_unsigned_long_long2
	
	not		eax
	not		edx
	add		eax, 1
	adc		edx, 0
	pop		ebx
	or		bl, minus_cast_flag
	push	ebx
	jmp		.print_unsigned_long_long2

.print_unsigned_long_long
	mov		ecx, [ebp - 16]
	get_arg eax
	get_arg edx
	mov		[ebp - 16], ecx

.print_unsigned_long_long2
	inc		esi
	push	edx
	push	eax
	call	hw_unsigned_long_long_to_string		
	pop		ebx
	pop		ebx
	jmp		.print_all

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

.print_signed_int
	mov		ecx, [ebp - 16]
	get_arg ebx
	mov		[ebp - 16], ecx
	cmp		ebx, 0
	jge		.print_unsigned_int2
	not		ebx
	add		ebx, 1
	pop		eax
	or		al, minus_cast_flag
	push	eax
	jmp		.print_unsigned_int2
	
.print_unsigned_int
	mov		ecx, [ebp - 16]
	get_arg ebx
	mov		[ebp - 16], ecx
.print_unsigned_int2
	inc		esi
	push	ebx
	call	hw_unsigned_int_to_string ;eax <- length
	pop		ebx				;this is number
.print_all	
	pop		edx				;flags
	pop		ebx				;width
	cmp		eax, ebx		;
	jae		.just_print_int
	
	mov		ecx, ebx	;ecx <- count of not number synbols
	sub		ecx, eax
	
	test	dl, minus_flag
	jz		.not_minus_flag
	copy
	mov		al, ' '
	rep		stosb
	jmp		.end_main_loop

.not_minus_flag
	test	dl, zero_flag
	jz		.not_zero_flag
	
	dec		eax					;WTF
	mov		ebx, number			;
	add		ebx, eax
	cmp		[ebx], byte '+'
	je		.signed
	cmp		[ebx], byte '-'
	je		.signed
	cmp		[ebx], byte ' '
	je		.signed
	inc		eax
	jmp		.end_signed

.signed
	push	eax
	mov		al, [ebx]
	stosb
	pop		eax
.end_signed
	push	eax

	mov		al, '0'
	rep		stosb
	pop		eax
	copy	
	jmp		.end_main_loop

.not_zero_flag
	
	push	eax
	mov		al, ' '
	rep		stosb
	pop		eax
	copy	
	jmp		.end_main_loop

.just_print_int
	copy
	jmp		.end_main_loop

.bad_sequence
	pop		eax
	pop		eax
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
	
	pop		ecx
	pop		ebx
	pop		esi
	pop		edi
	mov		esp, ebp
	pop		ebp
	xor		eax, eax
	ret

section .bss
number	resb 20

section .data
plus_flag		equ 1
space_flag		equ 2
minus_flag		equ 4
zero_flag		equ 8
minus_cast_flag equ 16 


