global hw_sprintf

%define PLUS_FLAG 1
%define ALIGN_LEFT_FLAG 2
%define SPACE_FLAG 4
%define LL_FLAG 8
%define Z_FLAG 16
%define UNSIGNED_FLAG 32
%define NEGATIVE_FLAG 64

%define setf(f) or edi, f 	 ; set flag
%define testf(f) test edi, f ; check if flag is set

section .text

hw_sprintf:
	push ebp
	mov ebp, esp
	push esi
	push eax
	push ecx
	mov ebx, [ebp + 8] ; first argument is in ebx now (buffer)
	mov eax, [ebp + 12] ; second arguments is in eax now (format string)
	add ebp, 16 ; ebp is pointing on first argument now

.loop:
	cmp byte [eax], 0
	je .write_symbol  ; the last symbol in buffer, write it to set end of the buffer
	cmp byte [eax], 0 ; finish if it's last symbol of the format string
	je .end
	cmp byte [eax], '%' ; if symbol isn't % write it
	jne .write_symbol
	jmp .after_percent

; restore registers at the and of executing program
.end:	
	pop ecx
	pop eax
	pop esi
	pop ebp
	xor eax, eax
	ret

; move one symbol from eax (format string) to ebx (buffer) and increment registers to get next symbols
.write_symbol:
	mov cl, byte [eax]
	mov byte [ebx], cl
	inc ebx
	inc eax
	cmp byte [eax - 1], 0
	je .end ; if it's the last symbol in buffer then finish program
	jmp .loop

; signed number is in edx
.set_negative_flag:
	setf(NEGATIVE_FLAG)
	xor ecx, ecx
	sub ecx, edx
	mov [ebp], ecx
	jmp .write_signed_int

; signed number is in (ecx:edx)
.set_negative_flag_ll:
	setf(NEGATIVE_FLAG)	
	not ecx
	not edx
	add ecx, 1
	adc edx, 0    ; negate long long number
	mov [ebp], ecx
	mov [ebp + 4], edx
	jmp .write_signed_ll

.set_plus_flag:
	setf(PLUS_FLAG)
	inc eax
	jmp .get_flags

.set_minus_flag:
	setf(ALIGN_LEFT_FLAG)
	inc eax
	jmp .get_flags
	
; set space flag if it isn't sign	
.maybe_set_space_flag:
	testf(PLUS_FLAG|NEGATIVE_FLAG)
	jz .set_space_flag
	inc eax
	jmp .get_flags

.set_space_flag:
	setf(SPACE_FLAG)
	inc eax
	jmp .get_flags
	
.set_z_flag:
	setf(Z_FLAG)
	inc eax
	jmp .get_width	

.set_unsigned_flag:
	setf(UNSIGNED_FLAG)
	inc eax
	jmp .parse_success	

; parse symbol after percent
.after_percent:
	xor edi, edi ; in edi only information about flags now
	mov ecx, eax ; because it can be bad parsing and need to write symbol on which eax pointed
	inc eax
	jmp .get_flags

.get_flags:
	cmp byte [eax], '+'
	je .set_plus_flag
	cmp byte [eax], '-'
	je .set_minus_flag
	cmp byte [eax], ' '
	je .maybe_set_space_flag
	cmp byte [eax], '0'
	je .set_z_flag
	jmp .get_width ; minimal width are now in esi

.get_size:
	cmp word [eax], 'll'
	jne .get_type
	add eax, 2 			; 2 bytes = ll
	setf(LL_FLAG)
	jmp .get_type

.get_type:	
	cmp byte [eax], 'u'
	je .set_unsigned_flag
	cmp byte [eax], '%'
	je .write_symbol   ; if type is % just write it
	cmp byte [eax], 'd'
	je .parse_success
	cmp byte [eax], 'i'
	je .parse_success
	jmp .unsuccessful_parsing

.parse_success:
	testf(LL_FLAG) ; check if number is 64-bit
	jnz .write_ll
	jmp .write_int

; parsing can be unsuccessful. So need to print % because it's just a symbol and return eax to position after %
.unsuccessful_parsing:	
	mov eax, ecx
	mov cl, byte [eax]
	mov byte [ebx], cl
	inc eax
	inc ebx
	jmp .loop

; get minimal width of the field
.get_width:
	xor esi, esi
	.loop6:
		cmp byte [eax], '0'
		jl .have_width
		cmp byte [eax], '9'
		jg .have_width
		xor ecx, ecx
		mov cl, byte [eax]
		sub cl, '0'
		inc eax ; next symbol
		imul esi, 10
		add esi, ecx
		jmp .loop6
	.have_width:	
		jmp .get_size

; write signed int by write sign and then using function hw_uint which writes unsigned int
.write_int:
	testf(UNSIGNED_FLAG)
	jnz .write_uint
	inc eax ; because here is only one case when eax pointed on something that we mustn't print after %
	mov edx, [ebp]
	cmp edx, 0
	jl .set_negative_flag
	jmp .write_uint

; write signed long long like in write_int
.write_ll:
	testf(UNSIGNED_FLAG)
	jnz .write_ull
	inc eax
	mov ecx, [ebp]
	mov edx, [ebp + 4]
	cmp edx, 0
	jl .set_negative_flag_ll
	jmp .write_ull

.write_minus:
	mov byte [ebx], '-'
	inc ebx
	testf(LL_FLAG)
	jnz .write_ull
	jmp .write_uint

.write_plus:
	mov byte [ebx], '+'
	inc ebx
	testf(LL_FLAG)
	jnz .continue_ll
	jmp .continue_int

.write_space:
	mov byte [ebx], ' '
	inc ebx
	testf(LL_FLAG)
	jnz .continue_ll
	jmp .continue_int

.check_space_flag:
	testf(SPACE_FLAG)
	jnz .write_space
	testf(LL_FLAG)
	jnz .continue_ll
	jmp .continue_int

.check_plus_flag:
	testf(PLUS_FLAG)
	jnz .write_plus
	jz .check_space_flag ; if first symbol not sign then it can be space
	testf(LL_FLAG)
	jnz .continue_ll
	jmp .continue_int

; call function hw_uitoa is here.
.write_signed_int:
	testf(NEGATIVE_FLAG)
	jnz .write_minus
.write_uint:
	testf(NEGATIVE_FLAG)
	jz .check_plus_flag ; check if we must to print sign for positive number
.continue_int:		
	push eax
	push ecx
	push edx
	call hw_uitoa
	add ebp, 4 ; ebp pointed on next argument 
	pop edx
	pop ecx
	pop eax
	jmp .loop
				 
; call function hw_luitoa is here
.write_signed_ll:
	testf(NEGATIVE_FLAG)
	jnz .write_minus
.write_ull:
	testf(NEGATIVE_FLAG)
	jz .check_plus_flag
.continue_ll:	
	push eax
	push ecx
	push edx
	call hw_luitoa
	add ebp, 8 ; ebp pointed on next argument
	pop edx
	pop ecx
	pop eax
	jmp .loop

; add unsigned int to buffer
hw_uitoa:
	push ebp
	push edi ; information about flags
	push esi ; minimal width
	mov esi, [ebp] ; current argument are now in esi 
	mov edi, ebx ; start position of our current buffer is in edi
	.loop1: ; unsigned int from esi to string
		xor edx, edx
		mov eax, esi
		mov ecx, 10
		div ecx
		add edx, '0' 
		mov [ebx], edx
		inc ebx
		mov esi, eax
		cmp esi, 0
		jne .loop1
	push ebx ; push ebx(position to print next symbol) on stack to save it's value
	mov edx, edi ; start position of our current buffer is in edx now
	dec ebx ; return ebx to the final inserted now position
	.loop2: ; reverse string and it looks like given unsigned int after this cicle
		mov al, byte [ebx]
		mov cl, byte [edi]
		mov byte [edi], al
		mov byte [ebx], cl
		dec ebx
		inc edi
		cmp edi, ebx
		jl .loop2		
	pop ebx ; save value of ebx(position to print next symbol) after cicle
	mov edi, ebx ; calculating length of number
	sub ebx, edx
	mov edx, ebx
	mov ebx, edi ; current length of number is in edx now, ebx- position of buffer in which must next symbol be printed
	pop esi ; minimal width
	pop edi ; information about flags
	testf(PLUS_FLAG|NEGATIVE_FLAG|SPACE_FLAG)
	jnz .increment_length ; increment length of number if need to print symbol before the number
	jmp .continue_write_uint
.continue_write_uint:	
	cmp esi, edx
	jg .align
	jmp .finish_write_uint
.increment_length:
	inc edx
	jmp .continue_write_uint	
.finish_write_uint:	
	pop ebp
	ret
.align: ; align the number 
	testf(ALIGN_LEFT_FLAG)
	jnz .align_left
	jmp .align_right
.align_left:
	sub esi, edx ; number of symbols to append is now in esi
	.loop7:
		mov byte [ebx], ' '
		inc ebx
		dec esi
		jnz .loop7
	jmp .finish_write_uint
.align_right:
	sub esi, edx ; number of symbols to append is in esi now
	mov eax, edx ; current length of number is in eax now
	mov edx, ebx ; final position of number is in edx now
	sub edx, eax ; edx = first position of number = final position of number - number length
	push edx ; save first position to stack
	push ebx ; save position to print next symbol on stack
	xor edx, edx
	dec ebx ; last position of number is in ebx now
	.loop10:
		sub ebx, edx ; begin to align from the last symbol of the number
		mov cl, byte [ebx]
		add ebx, esi ; get position to print symbol by add symbol position to number of symbols to append
		mov byte [ebx], cl
		sub ebx, esi
		add ebx, edx ; return ebx to the last final symbol of the number, because i increment edx and ebx must point on this position
		inc edx
		cmp edx, eax
		jl .loop10	
	pop ebx ; restore value of ebx	
	add ebx, esi ; next symbol must be inserted to [ebx]
	pop edx ; restore value of edx	
	testf(Z_FLAG)
	jnz .align_right_with_zeros
	.loop8: ; just write spaces
		mov byte [edx], ' '
		inc edx
		dec esi
		jnz .loop8
	jmp .finish_write_uint	
.align_right_with_zeros:	
	.loop9: ; just write zeros
		mov byte [edx], '0'
		inc edx
		dec esi
		jnz .loop9
	jmp .finish_write_uint		

; add unsigned long long to buffer
hw_luitoa:
        push ebp
        push edi ; information about flags
        push esi ; minimal width
        mov edi, ebx ; start position of our current buffer is in edi
		push eax
		push edx ; save registers value
		mov edx, [ebp + 4]
		mov eax, [ebp] ; number = EDX:EAX
		mov ecx, 10
		.loop3:
			mov esi, eax ; save value of EAX in ESI
			xchg edx, eax ; EDX:EAX = EAX_START:EDX_START
			xor edx, edx  ; EDX:EAX = 0:EDX_START
			div ecx ; EDX:EAX = (EDX_START % 10):(EDX_START / 10)
			xchg esi, eax ; EDX:EAX = (EDX_START % 10):EAX_START
			div ecx ; EDX:EAX = (((EDX_START % 10) << 32 + EAX_START) % 10):(((EDX_START % 10) << 32 + EAX_START) / 10), now EDX is a new digit
			add dl, '0'
			mov byte [ebx], dl ; write char to buffer
			inc ebx
			mov edx, esi
			or esi, eax ; check if our number is ended
			cmp esi, 0
			jne .loop3
		pop edx
		pop eax ; restore registers			
        push ebx ; push ebx(position to print next symbol) on stack to save it's value
        mov edx, edi ; start position of our current buffer is in edx now
        dec ebx ; return ebx to the final inserted now position
        .loop5: ; reverse string and it looks like given unsigned int after this cicle
                mov al, byte [ebx]
                mov cl, byte [edi]
                mov byte [edi], al
                mov byte [ebx], cl
                dec ebx
                inc edi
                cmp edi, ebx
                jl .loop5
        pop ebx ; save value of ebx(position to print next symbol) after cicle
        mov edi, ebx ; calculating length of number
        sub ebx, edx
        mov edx, ebx
        mov ebx, edi ; current length of number is in edx now, ebx- position of buffer in which must next symbol be printed
        pop esi ; minimal width
        pop edi ; information about flags
        testf(PLUS_FLAG|NEGATIVE_FLAG|SPACE_FLAG)
        jnz .increment_length_ll ; increment length of number if need to print symbol before the number
        jmp .continue_write_ull
.continue_write_ull:
        cmp esi, edx
        jg .align_ll
        jmp .finish_write_ull
.increment_length_ll:
        inc edx
        jmp .continue_write_ull
.finish_write_ull:
        pop ebp
        ret
.align_ll: ; align the number
        testf(ALIGN_LEFT_FLAG)
        jnz .align_left_ll
        jmp .align_right_ll
.align_left_ll:
        sub esi, edx ; number of symbols to append is now in esi
        .loop11:
                mov byte [ebx], ' '
                inc ebx
                dec esi
                jnz .loop11
        jmp .finish_write_ull
.align_right_ll:
        sub esi, edx ; number of symbols to append is in esi now
        mov eax, edx ; current length of number is in eax now
        mov edx, ebx ; final position of number is in edx now
        sub edx, eax ; first position of number = final position of number - number length
        push edx ; save first position to stack
        push ebx ; save porition to print next symbol on stack
        xor edx, edx
        dec ebx ; last position of number is in ebx now
        .loop12:
                sub ebx, edx ; begin to align from the last symbol of the number
                mov cl, byte [ebx]
                add ebx, esi ; get position to print symbol by add symbol position to number of symbols to append
                mov byte [ebx], cl
                sub ebx, esi
                add ebx, edx ; return ebx to the last final symbol of the number, because i increment edx and ebx must point on this position
                inc edx
                cmp edx, eax
                jl .loop12
        pop ebx ; restore value of ebx
        add ebx, esi ; next symbol must be inserted to [ebx]
        pop edx ; restore value of edx
        testf(Z_FLAG)
        jnz .align_right_with_zeros_ll
        .loop13: ; just write spaces
                mov byte [edx], ' '
                inc edx
                dec esi
                jnz .loop13
        jmp .finish_write_ull
.align_right_with_zeros_ll:
        .loop14: ; just write zeros
                mov byte [edx], '0'
                inc edx
                dec esi
                jnz .loop14
        jmp .finish_write_ull

