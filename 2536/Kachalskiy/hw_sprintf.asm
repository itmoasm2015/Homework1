global hw_sprintf
	
section .text

plus	equ 1<<0
space	equ 1<<1
minus	equ 1<<2
zero	equ 1<<3	; zero_padding
unsigned	equ 1<<5
negative	equ 1<<6
llong	equ 1<<7	; ll
sign_done  equ 1<<8
	
hw_sprintf:
	push ebp		; save registers
	mov ebp, esp
	sub esp, 20		;allocate variables
	push ebx
	push esi
	push edi
		
	mov edi, [ebp + 8]	; edi = buffer
	mov esi, [ebp + 12]	; esi = format string

	%define arguments [ebp - 4]; pointer to arguments
	%define flags [ebp - 8]
	%define width [ebp - 12]
	
	; create variables
	mov arguments, ebp
	add dword arguments, 16
	mov dword flags, 0
	mov dword width, 0
	
	.loop:	
		cmp byte [esi], 0	;finish of string
		jz .finish
		cmp byte [esi], '%'	;if start parsing format string
		je .call
		lodsb
		mov [edi], eax		;write symbol
		inc edi
		jmp .loop
		.call:
			call parse
		jmp .loop
		
	.finish:
	mov byte [edi], 0	;write Null char

	pop edi
	pop esi
	pop ebx
	add esp, 20		;reallocate variables
	pop ebp
	xor eax, eax		
	ret

; parse(format, buffer);
;Takes:
;	esi - format string
;	edi - buffer
parse:
	push edx
	push eax
	inc esi	;skip first symbol (=%)
	push esi
	lodsb

	mov dword flags, 0
	mov dword width, 0

	%macro get_flags 2	; if certain flag occurred go and parse it
		cmp al, %1
		jne %%skip
		or dword flags, %2
		lodsb
		jmp .parse_flags
		%%skip:	
	%endmacro

	.parse_flags:
	get_flags '+', plus
	get_flags ' ', space
	get_flags '-', minus
	get_flags '0', zero

	test dword flags, minus
	jz .count_width
	test dword flags, zero
	jz .count_width
	sub dword flags, zero ; if we found minus then ignore occurrence of zero
	
	.count_width:	
		cmp al, '0'	
		jl .finished_width
		cmp al, '9'
		jg .finished_width	;symb is in '0'...'9'
		sub al, '0'
		push eax
		push edx
		mov eax, width
		mov edx, 10
		mul edx			;eax = width * 10
		mov width, eax
		pop edx
		pop eax
		add width, al
		lodsb
		jmp .count_width
	.finished_width:

	cmp al, 'l'
	jne .size_parsed
	cmp byte [esi], 'l'
	jne .exception
	inc esi			;skip "ll"
	lodsb
	or dword flags, llong
	.size_parsed:
	
	cmp al, '%'
	je .percent
	cmp al, 'i'
	je .write
	cmp al, 'd'
	je .write
	cmp al, 'u'
	jne .exception		
	or dword flags, unsigned
	jmp .write

	.write:
	call print_number
	jmp .finish
	
	.percent:
	mov byte [edi], '%'
	inc edi
	jmp .finish
	
	.exception:		
	pop esi
	mov byte [edi], '%'	;restore skipped symbol at the begin
	inc edi
	push esi	;pop at the end must be correct
	
	.finish:
	pop edx
	pop eax
	pop edx
	ret



;print_number(buffer)
;Takes:
;	edi - buffer
print_number:
	push ecx
	push ebx
	push edx
	push esi
	
	mov eax, arguments
	mov eax, [eax]		;get arguments
	add dword arguments, 4	;set pointer to next argument

	test dword flags, llong
	jz .check_if_int
	mov edx, arguments
	mov edx, [edx]	        ;if (long) get second part of number
	add dword arguments, 4
	
	test dword flags, unsigned
	jnz .divide
	test edx, edx
	jge .divide
	or dword flags, negative

	not eax
	not edx
	add eax, 1
	adc edx, 0
	jmp .divide
	
	.check_if_int:
	test dword flags, unsigned
	jnz .divide
	test eax, eax
	jge .divide		
	or dword flags, negative	;num < 0
	neg eax
	
	.divide:
	mov ebx, width		;ebx = width
	mov esi, 10
	push 0			;watch point in stack ( to find sequence)
	test dword flags, llong
	jnz .divide_ulong
	
	.divide_uint:		;put number by digits on stack
		mov edx, 0	; 0:eax
		div esi	;(eax % 10):(eax / 10)
		add edx, '0'	; int to char
		push edx
		dec ebx	
		cmp eax, 0	;if (done)
		jnz .divide_uint
	jmp .check_align

	.divide_ulong:		;number is in edx:eax
		mov ecx, eax  ; save value of eax in ecx
		xchg edx, eax ; edx:eax = eax:edx
		xor edx, edx  ; 0:edx
		div esi	      ; (edx % 10):(edx / 10)
		xchg ecx, eax ; (edx % 10):eax
		div esi	      ; (((edx % 10) << 32 + eax) % 10):(((edx % 10) << 32 + eax) / 10)
		add edx, '0'  ;int -> char
		push edx      
		dec ebx
		mov edx, ecx
		or ecx, eax ;check finish
		cmp ecx, 0
		jne .divide_ulong

	.check_align:
	dec ebx			;add space for sign
	test dword flags, minus
	jnz .print_sign
	test dword flags, zero
	jnz .print_sign
	jmp .check_for_errors

	.print_sign:
	or dword flags, sign_done
	test dword flags, negative ;
	jz .plus_sign
	mov byte [edi], '-'
	inc edi
	test dword flags, zero
	jnz .check_for_errors	;if (!zero) print number
	jmp .print_number	;after sign

	.plus_sign:
	test dword flags, plus
	jz .sign_space
	mov byte [edi], '+'
	inc edi
	test dword flags, zero
	jnz .check_for_errors	
	jmp .print_number
	
	.sign_space:
	test dword flags, space
	jz .no_sign
	mov byte [edi], ' '
	inc edi
	test dword flags, zero
	jnz .check_for_errors	
	jmp .print_number

	.no_sign:
	inc ebx		;sign wasn't printed
	test dword flags, minus 
	jnz .print_number	;align left & no sign then print number
	jmp .check_for_errors	;align right & no sign then print char to fill
	
	.check_for_errors:
	cmp dword width, 0		
	jz .finished_width		;width wasn't set
	cmp ebx, 0		
	jle .finished_width		;number width is bigger than minimum width

	.print_width:
	xor ecx,ecx
	mov ecx, ' '
	test dword flags, zero
	jz .print_width_loop
	mov ecx, '0'
	
	.print_width_loop:		
		cmp ebx,0
		jz .finished_width
		mov [edi], ecx	;ecx is character to fill
		inc edi
		dec ebx
		jmp .print_width_loop

	.finished_width:
	test dword flags, minus
	jnz .finish_of_write_num		 ;if align left - all done
	test dword flags, sign_done ;sign placed after ' '
	jz .print_sign		    
	
	.print_number:
		pop edx
		cmp edx, 0
		jz .finish_print_number
		mov [edi], edx	;print char
		inc edi		;update ptr
		jmp .print_number
	.finish_print_number:
	test dword flags, minus ;if align left, after number fill width
	jnz .check_for_errors

	.finish_of_write_num:

	pop esi
	pop edx
	pop ebx
	pop ecx
	ret
