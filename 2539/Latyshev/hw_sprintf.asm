global hw_sprintf

;if [esi] shows flag, set this flag into al
;first argument  - flag symbol
;second argument - label to go in case of not detecting this flag
;third argument  - flag number (number with one setted bit)
%macro parse_flag 3 
	cmp		[esi], byte %1
	jne		%2
	or		al, %3
	inc		esi
	mov		ah, 1
%endmacro

;get next function argument. address always in [ebp - 16]
;argument - where to write this function argument
%macro get_arg 1
	mov		ecx, [ebp - 16]
	mov		%1, [ecx]
	add		ecx, 4
	mov		[ebp - 16], ecx
%endmacro

;get two next function argument. use for long long numbers.
;arguments - where to write this function arguments
%macro get_args 2
	mov		ecx, [ebp - 16]
	mov		%1, [ecx]
	add		ecx, 4
	mov		%2, [ecx]
	add		ecx, 4
	mov		[ebp - 16], ecx
%endmacro

;reverse and copy eax bytes from [number] to [edi]  
%macro copy 0
	push	edx					;save current state
	push	ecx
	push	ebx
	
	mov		edx, number			;
	add		edx, eax			; 
	dec		edx					;edx point to last symbol in number
	mov		ecx, eax			;set count of repeating

%%lp: mov		bl, [edx]		;
	mov		[edi], bl			;mov [edi], [edx]
	dec		edx					
	inc		edi					
	loop	%%lp

	pop		ebx					;load current state
	pop		ecx
	pop		edx
%endmacro

;check if the flag was setted and write sign symbol if needed
;first argument  - flag number
;second argument - sign symbol
;third argument  - label to go in case of flag wasn't setted
%macro check_flag 3
	test	al, %1 			
	jz		%3		
	mov		[edi], byte %2
	inc		edi
%endmacro

section .text

;int hw_unsigned_int_to_string(unsigned int x, unsigned int f)
;write	string representation of x to [number] in reverse order
;if format demand sign - sign will be written too, 
;also write '-' if cast from negative signed int to unsigned int
;return size of string representation unsigned int x
;low 5 bytes of f - mask of flags
;use minus_cast_flag, plus_flag and space_flag 

hw_unsigned_int_to_string:
	push	ebp					;save current state
	mov		ebp, esp
	push	edi
	push	ecx
	
	mov		eax, [ebp + 8]		;eax <- first argument (unsigned int)
	mov		edi, number			;edi - pointer for writing
    mov ecx, 10					;ecx <- base of numeral system  

.loop:
    xor edx, edx				
    div ecx						;div edx:eax to ecx, in edx - current digit
    add edx, '0'				;compute digit_symbol code
    mov [edi], edx				;write digit to edi
    inc edi
    test eax, eax				;check that quotient isn't zero
    jnz .loop
	
	mov		eax, [ebp + 12]		;eax <-flags
	;check flags and write sign with macro

	check_flag minus_cast_flag, '-', .no_cast_minus
	jmp		short .end
.no_cast_minus
	check_flag plus_flag, '+', .no_plus
	jmp		short .end
.no_plus
	check_flag space_flag, ' ', .end
.end
	
	mov		eax, edi			;
	sub		eax, number			;eax <- count of recorded bytes
	
	pop		ecx					;load current state
	pop		edi
	mov		esp, ebp
	pop		ebp
	ret


;int hw_unsigned_long_long_to_string(unsigned long long x, unsigned int f)
;full analogue of hw_unsigned_int_to_string for unsigned long long

hw_unsigned_long_long_to_string
    push	ebp					;save current state
    mov		ebp, esp
    push	edi
	push	esi
    push	ecx

    mov		eax, [ebp + 8]		;
    mov		edx, [ebp + 12]		;edx:eax <- first argument
	mov		edi, number			;edi <- pointer for writing 
    mov		ecx, 10				;ecx <- base of numeral system

.loop:	; current number - (edx:eax)
        ; edx - high_half
        ; eax - low_half
    mov		ebx, eax			;save low_half to ebx
    mov		eax, edx 
    xor		edx, edx	
    div		ecx					;div (0:high_half) by base
    mov		esi, eax			;save high_half_quotient to esi
    mov		eax, ebx
    div		ecx					;div (high_half_rem:low_half) by base
    add		edx, '0'			;
    mov		[edi], edx			;write digit to edi
    inc		edi					;
    mov		edx, esi			;load high_half_quotient
    test	eax, eax
    jne		.loop
    test	edx, edx
    jne		.loop

	mov		eax, [ebp + 16]		;eax <- flags
	;check flags with macro

	check_flag minus_cast_flag, '-', .no_cast_minus
	jmp		short .end
.no_cast_minus
	check_flag plus_flag, '+', .no_plus
	jmp		short .end
.no_plus
	check_flag space_flag, ' ', .end
.end

	mov		eax, edi			;
	sub		eax, number			;eax <- count of recorded bytes
	
    pop		ecx					;load current state
	pop		esi
	pop		edi
    mov		esp, ebp
    pop		ebp
	ret

;void hw_sprintf(char* out, const char* format, ...)
;write string from format to out with substitution of escape sequence to arguments.
;for full information see https://github.com/itmoasm2015/Homework1/blob/master/task.pdf

hw_sprintf:
	push	ebp					;save current state
	mov		ebp, esp
	push	edi
	push	esi
	push	ebx
	
	mov		edi, [ebp + 8]		;edi <- out
	mov		esi, [ebp + 12]		;esi <- format
	lea		ecx, [ebp + 16]		;
	push	ecx					;save pointer for arguments to [ebp - 16]  
	
	;check if format is empty
	cmp		[esi], byte 0
	je		.end	

.main_loop
	push	esi					;save current pointer for format
	cmp		[esi], byte '%'		;check start escape sequence
	jne		.just_print_one_pop
	
	inc		esi
	
	cmp		[esi], byte 0		;check if string ends with '%'	
	je		.print_last_symbol	

	;parse flags
	xor		al, al				;al for flags
.plus
	mov		ah, 0				;ah set to 1 if any of flags was found, else it will be zero
	parse_flag '+', .space, plus_flag
.space
	parse_flag ' ', .minus, space_flag
.minus
	parse_flag '-', .zero, minus_flag
.zero
	parse_flag '0', .end_parse_flag, zero_flag
.end_parse_flag
	test	ah, ah	
	jne		.plus				;if flag was found, continue
	push	eax					;save flags to stack

	;parse width	
	xor		eax, eax			;eax for width
	mov		ecx, 10				;ecx <- base of numeral system
.loop_width
	xor		ebx, ebx			;
	mov		bl, [esi]			;bl <- current symbol
	sub		bl, '0'				;
	cmp		bl, 9				;check that bl is digit
	ja		.end_parse_width
	mul		ecx
	add		eax, ebx
	inc		esi
	jmp		short .loop_width
.end_parse_width
	pop		ebx
	push	eax					; save width to stack
	push	ebx					; save flags to top of stack

	;parse size
	cmp		[esi], byte 'l'		;check ll 
	jne		.print_int
	inc		esi
	cmp		[esi], byte 'l'
	jne		.bad_sequence	
	inc		esi
	
	;print long long
	;parse type
	cmp		[esi], byte 'u'		
	je		.print_unsigned_long_long
	cmp		[esi], byte '%'				
	je		.just_print_three_pop
	cmp		[esi], byte 'i'
	je		.print_signed_long_long
	cmp		[esi], byte 'd'
	je		.print_signed_long_long
	jmp		.bad_sequence	

.print_signed_long_long
	get_args eax, edx			;edx:eax <- signed long argument
	cmp		edx, 0				;check the argument is negative
	jge		.print_unsigned_long_long2
	
	not		eax					;bit magic for negate number 
	not		edx
	add		eax, 1
	adc		edx, 0
	pop		ebx					;set minus_cast_flag
	or		bl, minus_cast_flag
	push	ebx
	jmp		short .print_unsigned_long_long2

.print_unsigned_long_long
	get_args eax, edx			;edx:eax <- unsigned long argument

.print_unsigned_long_long2
	inc		esi					
	push	edx
	push	eax
	call	hw_unsigned_long_long_to_string		
	pop		ebx
	pop		ebx
	jmp		short .print_all

.print_int
	;parse type
	cmp		[esi], byte 'u'
	je		.print_unsigned_int
	cmp		[esi], byte '%'
	je		.just_print_three_pop
	cmp		[esi], byte 'i'
	je		.print_signed_int
	cmp		[esi], byte 'd'
	je		.print_signed_int
	jmp		.bad_sequence

.print_signed_int
	get_arg ebx					;ebx <- signed int argument
	cmp		ebx, 0				;check the argument is negative
	jge		.print_unsigned_int2
	not		ebx					;bit magic for negate number
	add		ebx, 1
	pop		eax					;set minus_cast_flag
	or		al, minus_cast_flag	
	push	eax
	jmp		short .print_unsigned_int2
	
.print_unsigned_int
	get_arg ebx
.print_unsigned_int2
	inc		esi
	push	ebx
	call	hw_unsigned_int_to_string ;eax <- length
	pop		ebx					
.print_all	
	pop		edx					;flags
	pop		ebx					;width
	cmp		eax, ebx			;
	jae		.just_print_all
	
	mov		ecx, ebx			;ecx <- count of non-digit symbols
	sub		ecx, eax
	
	test	dl, minus_flag		;check minus_flag
	jz		.not_minus_flag

	;minus_flag write
	copy						
	mov		al, ' '
	rep		stosb
	jmp		.end_main_loop

.not_minus_flag
	test	dl, zero_flag
	jz		.not_zero_flag
	
	;zero_flag write
	dec		eax					;for signed length without sign
	mov		ebx, number			;
	add		ebx, eax			;ebx <- last symbol of reverse string in label number
	cmp		[ebx], byte '+'		;check if it is sign
	je		.signed
	cmp		[ebx], byte '-'
	je		.signed
	cmp		[ebx], byte ' '
	je		.signed				
	inc		eax					;without sign
	jmp		short .end_signed

.signed
	push	eax					;print sign
	mov		al, [ebx]
	stosb
	pop		eax
.end_signed
	push	eax					;print without sign
	mov		al, '0'
	rep		stosb
	pop		eax
	copy	
	jmp		.end_main_loop

.not_zero_flag
	;not zero_flag and not minus_flag write
	push	eax
	mov		al, ' '
	rep		stosb
	pop		eax
	copy	
	jmp		.end_main_loop

.just_print_all
	copy
	jmp		.end_main_loop

.bad_sequence
	add		esp, 8				;drop out width and flags
	pop		eax					;
	mov		ecx, esi			;ecx <- pointer for after last symbol
	pop		esi					;esi <- pointer for first symbol of sequence
	sub		ecx, esi			;ecx <- count symbols in bad sequence 
	cld
	rep		movsb
	jmp		.end_main_loop

.just_print_three_pop
	add		esp, 8				;drop out width and flags
.just_print_one_pop
	add		esp, 4				;drop out pointer for first symbol of sequence
	cld
	movsb

.end_main_loop
	cmp		[esi], byte 0
	jne		.main_loop 
	jmp		short .end

.print_last_symbol
	add		esp, 4
	dec		esi
	cld
	movsb

.end
	mov		[edi], byte 0
	
	pop		ecx					;load current state
	pop		ebx
	pop		esi
	pop		edi
	mov		esp, ebp
	pop		ebp
	xor		eax, eax
	ret

section .bss
number	resb 21					;buffer for writing number

section .data
plus_flag		equ 1			;flags
space_flag		equ 2
minus_flag		equ 4
zero_flag		equ 8
minus_cast_flag equ 16 
