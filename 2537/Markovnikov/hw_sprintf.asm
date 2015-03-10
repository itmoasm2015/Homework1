global  hw_sprintf
section .bss
        out_str:	resd 1
        temp:		resd 1
        tmp:  		resd 1
        div_h       	resd 1
        ans:        	resd 1
section .text
	%assign		PLUS_FLAG	1	    ; is used for showing sign
	%assign		SPACE_FLAG	1 << 1	; is used for placing space at the first position
	%assign		MINUS_FLAG	1 << 2	; is used for showing minus
	%assign		ZERO_FLAG	1 << 3	; is used for showing zeroes
	%assign		LONG_FLAG	1 << 4	; means that number is unsigned
	%assign		UNSIGN_FLAG	1 << 5	; means that number is 64-bit type
	%assign		SIGN_FLAG	1 << 6	; shows that number is negative
	%assign     	CTRL_FLAG   1 << 7  ; shows that there was correct procent
	%assign     	DEG         4294967296 / 10
	%assign     	DEG2        4294967295

	; converts number to string
	; arguments:
	;	eax - number
	;	edx - flag
	;	ebp - oldest part of ll (if it's said in flag)
	; result:
	;	out - string
	itoa:
        	test	edx, LONG_FLAG
        	jz	.num_32		    	; print number of 32-bit type
        	push    ecx
            	push    ebx
            	push    edx 
            	mov     ecx, 0
            	call    num_64
            	jmp     .set_sign
	.num_32:
        	test	edx, UNSIGN_FLAG
        	jnz	.unsign		    	; print as unsigned number
        	cmp	eax, 0		    	; if >= 0
        	jge	.unsign
        	or	edx, SIGN_FLAG 		; set flags
		or 	edx, PLUS_FLAG
        	neg	eax		        ; take absolute value of eax
	.unsign:
        	push	ecx
        	push	ebx
        	push	edx
        	mov	ebx, 10
        	mov	ecx, 0
	.div:				        ; takes digits
        	mov	edx, 0
       		div	ebx		        ; eax / 10
        	add	dl, '0'
        	push	edx
        	inc	ecx		        ; counter
        	cmp	eax, 0
        	jnz	.div		    	; continue to divide
        	mov	edx, [esp + ecx * 4]	; return flag to edx
        	.set_sign:
	        test    edx, SIGN_FLAG		; check sign of argument
       		jz      .try_plus	    	; try to set plus
       		inc     ecx		        ; counter
       		push    '-'		        ; print minus
       		jmp     .flag
	.try_plus:
       		test	edx, PLUS_FLAG		; if plus flag
        	jz	.try_space
        	inc	ecx		        ; counter
        	push	'+'		        ; print plus symbol
        	jmp	.flag
	.try_space:
        	test	edx, SPACE_FLAG 	; if space flag
        	jz	.flag
        	inc	ecx		        ; counter
        	push	' '		        ; print space
	.flag:
        	test	edx, MINUS_FLAG		; if minus flag
        	jnz	.print_result		; print result to out_string
        	test	edx, ZERO_FLAG		; if zero flag
       	 	jz	.sub_zero	    	; try to print zeroes
        	mov	ebx, edx
        	shr	ebx, 8
        	sub	ebx, ecx	    	; skip ecx digits
        	test	edx, PLUS_FLAG | SPACE_FLAG
        	jz	.print_zeroes
        	pop	ebp
	.print_zeroes:
        	cmp	ebx, 0			; while ebx >= 0
        	jle	.break_zeroes
        	push	'0'		        ; print zero
        	inc	ecx		        ; counter
        	dec	ebx
        	jmp	.print_zeroes		; loop
	.break_zeroes:
        	test	edx, PLUS_FLAG | SPACE_FLAG
        	jz	.print_result
        	push	ebp
        	jmp	.print_result
	.sub_zero:
        	mov	ebx, edx
        	shr	ebx, 8
        	sub	ebx, ecx	    	; skip ecx digits
	.print_spaces:
        	cmp	ebx, 0  		; while ebx >= 0
        	jle	.print_result
        	push	' '     		; print space
        	inc	ecx
        	dec	ebx
        	jmp	.print_spaces
	.print_result:
        	shr	edx, 8
        	mov	ebx, [out_str]
	.loop_count:
        	pop	eax
        	mov	[ebx], al
        	inc	ebx
        	dec	edx
        	dec	ecx
        	jnz	.loop_count
	.space_loop:
        	cmp	edx, 0		    	; while edx >= 0
        	jle	.break_spaces
       		mov	eax, ' '	    	; print space
        	mov	[ebx], al
        	inc	ebx
        	dec	edx
        	jmp	.space_loop		; loop
	.break_spaces:
        	mov	[out_str], ebx		; return result string
        	pop	edx
        	pop	ebx
        	pop	ecx
        	ret
     	;  same as .num_32 
     	;  result - eax
     	num_64:
            	test    edx, UNSIGN_FLAG	; if number - is not-negative
            	jnz     .posit
            	cmp     ebp, 0          	; >= 0
            	jge     .posit
            	xor     eax, DEG2
            	xor     ebp, DEG2
            	add     eax, 1
            	adc     ebp, 0
            	or      edx, SIGN_FLAG  	; set flag
            	or      edx, PLUS_FLAG  	; set abs
        	.posit:
            		mov     [tmp], edx
            		pop     edx
            		mov     [ans], edx
        	.div2:                 		; takes digits
            		mov     edx, 0
            		mov     edi, 10
            		div     edi
            		push    edx
            		push    eax
            		mov     eax, ebp
            		mov     edx, 0
            		div     edi
           	 	mov     ebx, edx
            		mov     edi, 6
            		mul     edi
            		push    eax
            		mov     eax, ebx
            		mul     edi
            		mov     edi, 10
            		mov     edx, 0
            		div     edi
            		push    edx
            		push    eax
           	 	mov     eax, ebp
            		mov     edi, DEG
            		mul     edi 
            		mov     edi, 0
            		pop     ebx
            		add     eax, ebx
            		adc     edx, 0 
            		pop     ebx
            		add     edi, ebx
            		pop     ebx
            		add     eax, ebx
            		adc     edx, 0    
            		pop     ebx
            		add     eax, ebx
            		adc     edx, 0
            		pop     ebx
            		add     edi, ebx        
            		mov     ebp, edx
            		cmp     edi, 10
            		jl      .sl    	     	; otherwise edi < 0 and so we don't need to subtract
            		sub     edi, 10
            		inc     eax
    		.sl:
            		add     edi, '0'
            		push    edi
            		inc     ecx
            		mov     edi, eax
            		or      edi, ebp
            		cmp     edi, 0
            		jnz     .div2
            	mov     edx, [ans]
            	push    edx
            	mov     edx, [tmp]
            	ret

	; void hw_sprintf(char *out, char const *format, ...)
	; arguments:
	;	out_str - out
	;	esi - format
	;	ebx - first argument
	hw_sprintf:
		push	ebx
		push	esi
       		push	edi
      		push	ebp
		mov	ebx, [esp + 20]
		mov	esi, [esp + 24]		; pointer to format string
       		mov	[out_str], ebx		; pointer to out string
      		lea	ebx, [esp + 28]		; pointer to the first argument
      		mov	[temp], ebx
	.percent:
     		cmp	byte [esi], 0		; if the end of the string
     	 	jz	.result			; write result
       		cmp	byte [esi], '%'		; if current char is percent
       		jz	.format			; parse term
       		mov	ebx, [out_str]
       		xor	eax, eax
       		mov	al, [esi]
       		mov	[ebx], al
       		inc	ebx		        ; take next argument
       		mov	[out_str], ebx
      		inc	esi
      		jmp	.percent
	.format:
        	xor	edx, edx	    	; refresh flag
       	 	inc	esi		        ; take next char in format string
        	push	esi
        	cmp	byte [esi], '%'		; if not percent again
        	jnz	.parse
        	add	esp, 4
        	inc	esi		        ; take next
        	mov	ebx, [out_str]
        	mov	edx, '%'	    	; set flag that there was percent
        	mov	[ebx], dl
        	inc	ebx		        ; take next argument
        	mov	[out_str], ebx
        	jmp	.percent	    	; loop
	.parse:				        ; firstly parse space
		cmp	byte [esi], ' '
		jnz	.plus		    	; if no space then try parse plus
		or	edx, SPACE_FLAG		; set flag
		inc	esi		        ; take next
		jmp	.parse		    	; loop
	.plus:				        ; parses plus
		cmp	byte [esi], '+'
		jnz	.minus		    	; try to parse minus
		or	edx, PLUS_FLAG		; set flag
		inc	esi		        ; take next
		jmp	.parse		    	; loop
	.minus:				        ; parses minus
        	cmp	byte [esi], '-'
        	jnz	.zero		    	; try to parse zero flag
        	or	edx, MINUS_FLAG		; set flag
        	inc	esi		        ; take next
        	jmp	.parse		    	; loop
	.zero:				        ; parses zero flag
        	cmp	byte [esi], '0'
        	jnz	.number		    	; try to parse number
        	or	edx, ZERO_FLAG		; set flag
        	inc	esi		        ; take next
        	jmp	.parse		    	; loop
	.number:			        ; parses number
		push	edx
        	xor	eax, eax	    	; refresh eax
	.loop0:
        	cmp	byte [esi], '0'		; >= 0
        	jb	.break		    	; break
        	cmp	byte [esi], '9'		; <= 9
        	ja	.break		    	; break
        	mov	edx, 10
        	mul	edx		        ; eax * 10
		xor 	edx, edx
        	mov	dl, [esi]
        	sub	edx, '0'
        	add	eax, edx	    	; 'current char' + eax * 10
        	inc	esi		        ; take next
        	jmp	.loop0
	.break:				        ; continue to parse l flag
        	pop	edx
        	cmp	byte [esi], 'l'
        	jnz	.d		        ; try to parse d flag
        	inc	esi		        ; take next
        	cmp	byte [esi], 'l'
        	jnz	.incorrect	    	; we get incorrect flag
        	inc	esi		        ; take next
        	or	edx, LONG_FLAG		; set flag
	.d:					; parses d flag
        	cmp	byte [esi], 'd'
        	jnz	.u		        ; try to parse u flag and we don't need to set flag
        	inc	esi		        ; take next
        	jmp	.flag
	.u:					; parses u flag
        	cmp	byte [esi], 'u'
        	jnz	.i			; try to parse i flag
        	or	edx, UNSIGN_FLAG	; set flag that it's unsigned number
        	inc	esi		        ; take next
        	jmp	.flag
	.i:				        ; parses i flag
        	cmp	byte [esi], 'i'
        	jnz	.incorrect  		; incorrect flag
        	inc	esi
	.flag:
        	shl	eax, 8
        	or	edx, eax	    	; set flag
        	mov	ebx, [temp]
        	mov	eax, [ebx]
        	add	ebx, 4
        	test	edx, LONG_FLAG
        	jz	.write		    	; if not ll flag then write the number
        	mov	ebp, [ebx]
        	add	ebx, 4
	.write:
        	mov	[temp], ebx
        	call	itoa
        	add	esp, 4		    	; take next pointer
        	jmp	.percent	    	; parse again
	.incorrect:
        	mov	edx, [out_str]
        	mov	ebx, '%'
        	mov	[edx], bl
        	inc	edx
        	mov	[out_str], edx
        	pop	esi
        	jmp	.percent	    	; continue to parse
	.result:        
		mov	edx, [out_str]
        	mov	ebx, 0
        	mov	[edx], ebx
        	pop	ebp
        	pop	edi
        	pop	esi
        	pop	ebx
        	ret
