global hw_sprintf
	
section .text

	;;format flags for parsing
FLAG_PLUS	equ 1<<0
FLAG_SPACE	equ 1<<1
FLAG_MINUS	equ 1<<2
FLAG_ZERO	equ 1<<3
FLAG_WIDTH	equ 1<<4
FLAG_UNSIGNED	equ 1<<5
FLAG_NEGATIVE	equ 1<<6
FLAG_LONG	equ 1<<7
FLAG_SIGN_DONE  equ 1<<8
	
hw_sprintf:
	push ebp		; save registers
	mov ebp, esp
	sub esp, 20		;allocate mem for variables
	push ebx
	push esi
	push edi
		
	mov edi, [ebp + 8]	; read buffer pointer
	mov esi, [ebp + 12]	; format string pointer

	%define arg_ptr [ebp - 4]; ptr to first unread arg
	%define flags [ebp - 8]
	%define width [ebp - 12]
	
	;; init variables
	mov arg_ptr, ebp
	add dword arg_ptr, 16
	mov dword flags, 0
	mov dword width, 0
	
	.loop:	
		cmp byte [esi], 0	;end of string
		jz .end
		cmp byte [esi], '%'	
		je .call
		lodsb
		mov [edi], eax		;write symb
		inc edi
		jmp .loop
		.call:
		call parse		;if next symb is '%'
		jmp .loop


	
	.end:
	mov byte [edi], 0	;write end of string
	;; restore registers
	pop edi
	pop esi
	pop ebx
	add esp, 20		;reallocate locals
	pop ebp
	xor eax, eax		
	ret

; function parses controlling expression
;; args:
	;; esi -> ptr to format string (starts with %)
	;; edi -> ptr to buffer
;; result: writes to buffer
parse:
	push edx
	push eax
	inc esi			;skip %
	push esi		;save esi in case expr is incorrect
	lodsb

	mov dword flags, 0
	mov dword width, 0

	%macro check_flag 2
		cmp al, %1
		jne %%skip
		or dword flags, %2
		lodsb
		jmp .parse_flags
		%%skip:	
	%endmacro

	.parse_flags:
	check_flag '+', FLAG_PLUS
	check_flag ' ', FLAG_SPACE
	check_flag '-', FLAG_MINUS
	check_flag '0', FLAG_ZERO

	test dword flags, FLAG_MINUS
	jz .parse_width
	test dword flags, FLAG_ZERO
	jz .parse_width
	sub dword flags, FLAG_ZERO ;if '-' flag is set, ignore '0' flag 
	
	.parse_width:	
		cmp al, '0'	
		jl .width_parsed
		cmp al, '9'
		jg .width_parsed	;symb is in '0'...'9'
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
		jmp .parse_width
	.width_parsed:

	cmp al, 'l'
	jne .size_parsed
	cmp byte [esi], 'l'
	jne .incorrect
	inc esi			;skip ll
	lodsb
	or dword flags, FLAG_LONG
	.size_parsed:
	
	cmp al, '%'
	je .percent
	cmp al, 'i'
	je .write
	cmp al, 'd'
	je .write
	cmp al, 'u'
	jne .incorrect		
	or dword flags, FLAG_UNSIGNED
	jmp .write

	.write:
	call write_number
	jmp .end
	
	.percent:
	mov byte [edi], '%'
	inc edi
	jmp .end
	
	.incorrect:		
	pop esi
	mov byte [edi], '%'		;write skipped at the begin
	inc edi
	push esi		;pop at the end must be correct
	
	.end:			;STACK: edx|eax|esi
	pop edx			;esi not needed to save
	pop eax
	pop edx
	ret



;writes number from arguments
	;; edi -> ptr to buffer
	;; esi,ecx saved and used
write_number:
	push ecx
	push ebx
	push edx
	push esi
	
	mov eax, arg_ptr
	mov eax, [eax]		;get number from arguments
	add dword arg_ptr, 4	;update arg_ptr

	test dword flags, FLAG_LONG
	jz .check_int
	mov edx, arg_ptr
	mov edx, [edx]	        ;get second part of number from args
	add dword arg_ptr, 4
	
	test dword flags, FLAG_UNSIGNED
	jnz .div
	test edx, edx
	jge .div
	or dword flags, FLAG_NEGATIVE

	not eax			;get absolute value
	not edx
	add eax, 1
	adc edx, 0
	jmp .div
	
	.check_int:
	test dword flags, FLAG_UNSIGNED
	jnz .div
	test eax, eax
	jge .div		
	or dword flags, FLAG_NEGATIVE	;num < 0
	neg eax				;get absolute value
	
	.div:
	mov ebx, width		;ebx is width counter
	mov esi, 10
	push 0			;used to find end of sequence in stack
	test dword flags, FLAG_LONG
	jnz .div_ulong
	
	.div_uint:		;put number by digits on stack
		mov edx, 0   	; 0:eax
		div esi		;(eax % 10):(eax / 10)
		add edx, '0' 	; int -> char
		push edx
		dec ebx	
		cmp eax, 0	;check end 
		jnz .div_uint
	jmp .check_align

	.div_ulong:		;number is in edx:eax
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
		or ecx, eax ;check end
		cmp ecx, 0
		jne .div_ulong

	.check_align:
	dec ebx			;space for sign
	test dword flags, FLAG_MINUS
	jnz .print_sign
	test dword flags, FLAG_ZERO
	jnz .print_sign
	jmp .check_width

	.print_sign:
	or dword flags, FLAG_SIGN_DONE
	test dword flags, FLAG_NEGATIVE ;'-' always printed
	jz .plus_sign
	mov byte [edi], '-'
	inc edi
	test dword flags, FLAG_ZERO
	jnz .check_width	;if zero flag not set, print number
	jmp .print_number	;after sign

	.plus_sign:
	test dword flags, FLAG_PLUS
	jz .sign_space
	mov byte [edi], '+'
	inc edi
	test dword flags, FLAG_ZERO
	jnz .check_width	
	jmp .print_number
	
	.sign_space:
	test dword flags, FLAG_SPACE
	jz .no_sign
	mov byte [edi], ' '
	inc edi
	test dword flags, FLAG_ZERO
	jnz .check_width	
	jmp .print_number

	.no_sign:
	inc ebx		;sign wasn't printed - width will fix it
	test dword flags, FLAG_MINUS 
	jnz .print_number	;align left, no sign -> print num
	jmp .check_width	;align right, no sign -> print char to fill
	
	.check_width:
	cmp dword width, 0		
	jz .width_done		;width wasn't set
	cmp ebx, 0		
	jle .width_done		;number width is bigger than minimum width

	.print_width:
	xor ecx,ecx
	mov ecx, ' '
	test dword flags, FLAG_ZERO
	jz .print_width_loop
	mov ecx, '0'
	
	.print_width_loop:		
		cmp ebx,0
		jz .width_done
		mov [edi], ecx	;ecx is character to fill
		inc edi
		dec ebx
		jmp .print_width_loop

	.width_done:
	test dword flags, FLAG_MINUS
	jnz .end_of_write_num		 ;if align left - all done
	test dword flags, FLAG_SIGN_DONE ;sign placed after ' '
	jz .print_sign		    
	
	.print_number:
		pop edx
		cmp edx, 0
		jz .end_of_print_num
		mov [edi], edx	;print char
		inc edi		;update ptr
		jmp .print_number
	.end_of_print_num:
	test dword flags, FLAG_MINUS ;if align left, after number fill width
	jnz .check_width

	.end_of_write_num:

	pop esi
	pop edx
	pop ebx
	pop ecx
	ret
