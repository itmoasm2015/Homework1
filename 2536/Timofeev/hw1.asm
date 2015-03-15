global hw_sprintf
global hw_ultoa
global hw_ltoa
global hw_utoa
global hw_itoa


section .bss
string: 	resb 100		;space for converted number
section .text

%assign FLAG_PLUS	 	1 << 8 	;force to show sign or not
%assign FLAG_SPACE		1 << 9 	;place space if have no sign
%assign FLAG_MINUS		1 << 10	;align to right or not
%assign FLAG_ZERO		1 << 11	;show zeros before
%assign NUM_LONG 		1 << 12 ;64-bit number or not
%assign NUM_UNSIGNED	1 << 13 ;unsigned number or not
%assign PERCENT_TYPE	1 << 14 ;print percent 
%assign BROKEN_SEQ		1 << 15 ;sequence is broken, print as is

%define setflag(b) or ebx, b 	;macro to set flags
%define testflag(b) test ebx, b ;macro to check flags

; void hw_ultoa(unsigned long long value, char * str)
; in:
;	EDX:EAX - input number
;	ESI 	- pointer to result string
; use:
;	ESI, EDI
; convert unsigned long long to string
hw_ultoa:
	push    ebp             
    mov     ebp, esp
    push 	edi
    push 	esi

    mov     eax, [ebp+8]    
    mov 	edx, [ebp+12]
    mov 	esi, [ebp+16]
    ;mov 	ecx, 10
.loop:
    mov 	ebx, eax 		;div long int, considered fact
    mov 	eax, edx 		;that 
    xor 	edx, edx 		;EDX:EAX % 10 = ((EDX%10):EAX)%10
    mov 	ecx, 10
    div 	ecx
    mov 	edi, eax
    mov 	eax, ebx
    mov 	ecx, 10
    div 	ecx

    add 	dl, '0'			;add char to string	
    mov 	[esi], dl
    inc 	esi

    mov 	edx, edi
    cmp 	eax, 0
    jne .loop

    mov 	edx, 0
    mov 	[esi], edx 		;null terminated string
    mov 	edi, [ebp+16] 	;"pointer" to first char in string
    dec 	esi 		  	;"pointer" to last char in string	
.rev_loop:
    mov 	al, [esi] 		;reverse string bytes
    mov 	bl, [edi]
    mov 	[esi], bl
    mov 	[edi], al	
    inc  	edi
    dec 	esi
    cmp 	edi, esi
    jle .rev_loop
.end:
    pop 	esi
    pop 	edi
    pop     ebp             
    ret
;===========================

; void hw_ltoa(long long value, char * str)
; in:
;	EDX:EAX - input number
;	ESI 	- pointer to result string
; use:
;	ESI	
; add sign if necessary, convert long long to unsigned long long, and call hw_ultoa
hw_ltoa:
	push 	ebp
	mov 	ebp, esp
	push 	esi
	
	mov     eax, [ebp+8]    
    mov 	edx, [ebp+12]
    mov 	esi, [ebp+16]
    cmp 	edx, 0			;check sign and add to string if needed
    jge .next
    mov 	[esi], byte '-'
    
    inc 	esi
    not 	eax 			;convert signed to unsigned
	not 	edx
	add 	eax, 1
	adc 	edx, 0
.next:
	push 	esi
	push 	edx
	push 	eax
	call 	hw_ultoa
	add 	esp, 12
	
	pop 	esi
	pop 	ebp
	ret
;===========================

; void hw_uitoa(unsigned int value, char * str)
; in:
;	EAX - input number
;	ESI - pointer to result string
; use:
;	ESI
; convert unsigned int to unsigned long long and call hw_ultoa
hw_uitoa:
	push 	ebp
	mov 	ebp, esp
	push 	esi
	
	mov     eax, [ebp+8]    
    mov 	esi, [ebp+12]
    xor 	edx, edx 
	push 	esi
	push 	edx
	push 	eax
	call 	hw_ultoa
	add 	esp, 12
	
	pop 	esi
	pop 	ebp
	ret	
;===========================

; void hw_itoa(int value, char * str)
; in:
;	EAX - input number
;	ESI - pointer to result string
; use:
;	ESI
; add sign if necessary, convert int to unsigned int and call hw_uitoa
hw_itoa:
	push 	ebp
	mov 	ebp, esp
	push 	esi
	
	mov     eax, [ebp+8]    
    mov 	esi, [ebp+12]

    cmp 	eax, 0 			;check sign and add to string if needed
    jge .next
    mov 	[esi], byte '-'
    inc 	esi
    not 	eax 			;convert signed to unsigned
    inc 	eax 
.next:
    xor 	edx, edx
    push 	esi
	push 	edx
	push 	eax
	call 	hw_ultoa
	add 	esp, 12
	pop 	esi
	pop 	ebp
	ret
;===========================

; in:
;	ESI - pointer to str
; out:
;	EAX - string length
strlen:
	xor 	eax, eax 		;result = 0
.loop
	inc 	eax
	cmp 	byte [esi], 0
	jne .loop
;===========================

; void hw_sprintf(char * out, const char * format, ...)
; in:
;	ESI - pointer to format buffer
;	EDI - pointer to out buffer
; use:
;	ESI, EDI, EBX
hw_sprintf:
	push 	ebp
	mov 	ebp, esp
	push 	ebx
	push 	edi
	push 	esi
    	
	mov 	edi, [esp + 20]	;out
	mov 	esi, [esp + 24]	;format
	lea 	ecx, [esp + 28] ;first element of (...)
	
.main_loop:
	nop
	cmp 	byte [esi], '%'	;escape sequence => start proceed
	je sequence_process		;after sequence_process we will jump to add_number 
							;with correct ESI, EDI and flags in EBX
							;after add_number we will jump to .main_loop
	
	movsb 					;plane symbol => add to out
	cmp 	byte [esi-1], 0	;last symbol was /0 => finish
	jne .main_loop

	
	pop 	esi
	pop 	edi
	pop 	ebx
	pop 	ebp
	ret
;===========================

; helper function to configure print flags
; in:
;	ESI - substring started from '%'
;	ECX - pointer to data
; out:
; 	EBX - print flags
;	ESI - sequence end pointer(if broken point to the first symbol after bad)
;	EDI - correct out pointer 
sequence_process:
	push 	esi
	push 	ecx 			;save pointer to data for future	
	inc 	esi
	xor 	ebx, ebx		;EBX will store format flags

.parse_falgs_loop:
	lodsb 					;read char
	cmp 	al, byte '+'
	je .set_plus
	cmp 	al, byte '-'
	je .set_minus
	cmp 	al, byte ' '
	je .set_space
	cmp 	al, byte '0'
	je .set_zero

	push 	ebx 			;save flags for future
	dec 	esi 			;we've read one extra char and should "unread" it
	xor 	edx, edx 		;set width to zero
	mov 	ecx, 10
.parse_width_loop:
	lodsb 					;read char
	;symbol is not a digit => finish loop
	cmp 	al, byte '0'
	jnge .parse_width_loop_end
	cmp 	al, byte '9'
	jnle .parse_width_loop_end

	xor 	ebx, ebx
	mov 	bl, al
	sub 	ebx, '0' 		;store digit
	mov 	eax, edx 		
	mov 	ecx, 10
	mul 	ecx				;multiply by 10 and add new digit 
	add 	eax, ebx 		;very new convert string to number algorithm
	mov 	edx, eax
	jmp .parse_width_loop
	
.parse_width_loop_end:
	dec 	esi 			;we've read one extra char and should "unread" it
	push 	edx 			;save width
	;stack state: (+0)width; (+4)flags; (+8)pointer to data; (+12)sequence first position
	mov 	ebx, [esp+4]	;restore flags
	;parse length "ll"(64 bit) or nothing(32 bit)
	cmp 	word [esi], 'll';we can check two symbols with one cmp
	jne .parse_length_end 	;not long, do nothing
	setflag(NUM_LONG)		;set long flag 
	mov 	[esp+4], ebx
	add 	esi, 2 			;skip two symbols
.parse_length_end


	;parse specification
	lodsb 					;read char
	cmp 	al, byte 'i'	
	je .sequence_process_end;it's okay, go away

	cmp 	al, byte 'd'
	je .sequence_process_end;it's okay, go away

	cmp 	al, byte 'u'
	je .set_unsigned

	cmp 	al, byte '%'
	je .set_percent_type

	;broken sequence => return as is
	mov 	ecx, esi 		;save sequence last position
	mov 	esi, [esp+12]	;restore sequence first position
.copy_loop	
	movsb 					;copy sequence char by char	
	cmp 	ecx, esi
	jne .copy_loop 			

.sequence_process_end
	nop 
	nop
	nop 
	;add 	esp, 12			;clear used stack
	jmp add_number			;print number or '%' to *out

; bit setters here
.set_plus:
	setflag(FLAG_PLUS)
	jmp .parse_falgs_loop

.set_minus:
	setflag(FLAG_MINUS)
	jmp .parse_falgs_loop

.set_space
	setflag(FLAG_SPACE)
	jmp .parse_falgs_loop

.set_zero
	setflag(FLAG_ZERO)
	jmp .parse_falgs_loop

.set_unsigned
	mov 	ebx, [esp+4]	;restore flags
	setflag(NUM_UNSIGNED)
	mov 	[esp+4], ebx
	jmp .sequence_process_end

.set_percent_type
	setflag(PERCENT_TYPE)
	jmp .sequence_process_end	
;===========================

; helper function to add number to *out
; in:
;	EDI - out pointer
;	EBX - format flags
;	ECX - pointer to number argument
; out:
;	EDI - correct out pointer 
;	ECX - correct pointer to next number argument
; use:
;	ESI
; nothing on stack
add_number:
	;stack state: (+0)width; (+4)flags; (+8)pointer to data; (+12)sequence first position
	nop
	nop
	nop
	nop
	mov 	ecx, [esp+8]
	push 	esi 			;save pointer to next input char
	push 	ecx 			;will be removed from stack before .done

	mov 	esi, string+1 	;+1 is for '+' or ' ' if needed
	testflag(PERCENT_TYPE)
	jnz .print_percent

	testflag(NUM_LONG)
	jnz .print_long
	
	jmp .print_int

.done:						
	mov 	ebx, [esp+4+4] 	;restore flags
	mov 	edx, [esp+4+0] 	;restore width
	push 	ecx 			;save pointer to data
	;now ESI is pointer to string with number 
	xor 	eax, eax 		;result = 0
	mov 	ecx, esi
.strlen_loop
	inc 	ecx
	cmp 	byte [ecx], 0
	jne .strlen_loop
	mov 	eax, ecx
	sub 	eax, esi

	sub 	edx, eax

	cmp 	[esi], byte '-'
	jne .add_space_or_plus
.add_space_or_plus_end

	;dec EDX - padding length  if we have any sign
	cmp 	[esi], byte '+'
	je .dec_edx
	cmp 	[esi], byte '-'
	je .dec_edx
	cmp 	[esi], byte ' '
	je .dec_edx

.check_paddings 			;will stay here with correct padding length 

	testflag(FLAG_MINUS)
	jnz .copy_loop 			;do nothing now, add padding later
	
	cmp edx, 0
	jg .fill_padding

.copy_loop
	movsb
	cmp 	byte [esi], 0	;last symbol was /0 => finish
	jne .copy_loop

	testflag(FLAG_MINUS) 	;fill padding after string
	jnz .fill_end_padding

.add_number_end
	pop 	ecx
	pop 	esi
	add 	esp, 16
	jmp hw_sprintf.main_loop  ;retrun to main
;-------------------------
.fill_end_padding
	cmp 	edx, 0
	jle .add_number_end
	.end_fill_loop
	mov 	[edi], byte ' '
	inc 	edi
	
	cmp 	edx, 0
	dec 	edx
	jne .end_fill_loop
	mov 	[edi], byte 0
	jmp .add_number_end

.fill_padding
	;fill between '+'\'-'\' ' and numbers, so inc esi if needed
	cmp 	[esi], byte '+'
	je .inc_esi
	cmp 	[esi], byte '-'
	je .inc_esi
	cmp 	[esi], byte ' '
	je .inc_esi
.set_char:
	testflag(FLAG_ZERO)
	jnz .set_char_zero
	mov 	al, ' '
	.fill_loop
	mov 	[edi], al
	inc 	edi
	dec 	edx
	cmp 	edx, 0
	jne .fill_loop
	
	jmp .copy_loop ;add string after padding

.set_char_zero
	mov 	al, '0'
	jmp .fill_loop

.inc_esi:
	movsb 					;save sign to out
	jmp .set_char

.dec_edx:
	dec 	edx 
	jmp .check_paddings

.add_space_or_plus:
	testflag(FLAG_PLUS)
	jnz .add_plus
	testflag(FLAG_SPACE)
	jnz .add_space
	jmp .add_space_or_plus_end

.add_plus
	dec 	esi
	mov 	[esi], byte '+'
	jmp .add_space_or_plus_end

.add_space
	dec 	esi
	mov 	[esi], byte ' '
	jmp .add_space_or_plus_end


.print_long:
	mov 	ecx, [esp] 		;the same prepare code for hw_ltoa and hw_ultoa
	push 	esi 			;EDI - pointer to converted string !!!!
	push 	dword [ecx+4]	;EDX
	push 	dword [ecx]		;EAX
	
	testflag(NUM_UNSIGNED)
	jnz .ulong
	jmp .long

.print_int
	nop
	mov 	ecx, [esp]		;the same prepare code for hw_itoa and hw_uitoa
	push 	esi 			;EDI - pointer to converted string
	push 	dword [ecx] 	;EAX
	
	testflag(NUM_UNSIGNED)
	jnz .uint
	jmp .int

.long:
	call 	hw_ltoa
	add 	esp, 12
	pop 	ecx 			;restore pointer
	add 	ecx, 8			;now ecx point to next number
	jmp .done
.ulong
	call 	hw_ultoa
	add 	esp, 12
	pop 	ecx 			;restore pointer
	add 	ecx, 8			;now ecx point to next number
	jmp .done
.int
	call 	hw_itoa
	add 	esp, 8
	pop 	ecx 			;restore pointer
	add 	ecx, 4			;now ecx point to next number
	jmp .done
.uint
	call 	hw_uitoa
	add 	esp, 8
	pop 	ecx 			;restore pointer
	add 	ecx, 4			;now ecx point to next number
	jmp .done

.print_percent:
	mov 	[edi], byte '%'
	inc 	edi
	mov 	[edi], byte 0
	;pop 	ecx 			;its hack, yep 
	jmp .add_number_end
;-------------------------
