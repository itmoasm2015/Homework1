section .text
	global hw_sprintf

; void hw_sprintf(char *out, char const *format, ...);
; EBP pointer to current command
; ESP pointer to stack
; ESI poinet to current parameter
; EDI pointer to format 4 bit
; ECX 
; EDX 
; EAX
; EBX
hw_sprintf:
	push ebp
	push edi
	push esi
	push ebx
	mov ecx, [esp + 20]		; add pointer to out to out
	mov [myout], ecx		;
	mov edi, [esp + 24]		; add pointer to format to edi
	mov esi, esp			;
	add esi, 28			; add pointer to current parameter
	jmp print_str
endall:
	pop ebx
	pop esi
	pop edi
	pop ebp
	ret

print_str:
	mov byte al, [edi]		; put current symbol to al
	mov ebx, 0			;
	mov [sign], ebx			; set fields zero
	mov [space], ebx		;
	mov [minus], ebx		;
	mov [zero], ebx			;
	mov [length], ebx		;
	mov [lenn], ebx			;
	mov [per], edi			;
	cmp byte al, '%'		; if s[i] == %
	jz parse
incorrect:
	mov ecx, [myout]		;
	mov [ecx], byte al		; write to out 1 char
	mov ecx, 1			;
	add [myout], ecx		; 
	add edi, 1			; next char
n_char:
	cmp byte al, 0			;if end of string return
	jnz print_str
	jmp endall 

parse:
	add edi, 1			; next char
	mov byte al, [edi]		;
	cmp byte al, 0			; if end of string return
	jz endall
	cmp byte al, '%'		; if s[i] == % print %
	jz incorrect
	cmp byte al, '+'		;
	jz set_sign			; set flag +
	cmp byte al, ' '		;
	jz set_space			; set flag space
	cmp byte al, '-'		;
	jz set_minus			; set flag -
	cmp byte al, '0'		;
	jz set_zero			; set flag 0
	cmp byte al, '1'		;
	jl types			
	cmp byte al, '9'		;
	jle set_length			; set length
types:
	cmp byte al, 'd'
	jz parameter_d			; type is d
	cmp byte al, 'u'
	jz parameter_u			; type is u
	cmp byte al, 'i'
	jz parameter_i			; type is i
	cmp byte al, 'l'
	jz parameter_ll			; type is ll
	mov edi, [per]			; if incorrect flags and type print expression
	mov byte al, [edi]
	jmp incorrect

set_sign:
	mov ebx, 1
	mov [sign], ebx			; set sign = 1
	jmp parse 
	
set_space:
	mov ebx, 1
	mov [space], ebx		; set space = 1
	jmp parse 

set_minus:
	mov ebx, 1
	mov [minus], ebx		; set minus = 1
	jmp parse 

set_zero:
	mov ebx, 1
	mov [zero], ebx			; set zero = 1
	jmp parse

set_length:
	mov ebx, 0
	mov [length], ebx		; set length
	mov byte cl, byte al
sl:
	sub byte cl, '0'
	mov eax, [length]
	mov ebx, 10			; multiply ebx to 10
	mul ebx
	mov [length], eax
	add [length], byte cl		; add lenght next digit
	add edi, 1
	mov byte cl, [edi]
	cmp byte cl, '0'
	jl esl
	cmp byte cl, '9'
	jle sl
esl:
	sub edi, 1
	jmp parse
	 	 
print_sign:
	mov ebx, 1
	cmp [sign], ebx			; if no need in sign return
	jnz end_ps
	mov eax, [esi]
	mov ecx, '-'			; sign is -
	cmp eax, 0
	jl add_sign
	mov ecx, '+'			; if eax > 0 sign is +
add_sign:
	push ecx
	add [lenn], ebx
	jmp end_ps

print_space:				; if need a space push space to stack
	mov ebx, 1
	cmp [sign], ebx
	jz end_psp
	mov ecx, ' '
	push ecx
	add [lenn], ebx
	jmp end_psp

align_left:				;if should align left print 0 or ' ' length - lenn times
	mov eax, 1
	cmp [minus], eax
	jnz end_alignl
	mov ecx, [length] 
	cmp [lenn], ecx
	jg end_alignl
	mov ebx, '0'
	cmp [zero], eax
	jz ali
	mov ebx, ' '
ali:
	mov eax, [myout]
	mov [eax], ebx
	mov ebx, 1
	add [myout], ebx
	add [lenn], ebx
	jmp align_left 

align_right:				;if should align right push ' ' to stack length - lenn times
	mov eax, 1
	cmp [minus], eax
	jz end_alignr
	mov ecx, [length] 
	cmp [lenn], ecx
	jge end_alignr
	mov ebx, ' '
	push ebx
	add [lenn], eax
	jmp align_right 

print_number:
	push -1				;push start symbol to stack
	mov eax, [esi]
	cmp eax, 0
	jg positive
	mov ebx, 1
	mov [sign], ebx
	neg eax				; take absolutely value
positive:	
	mov ebx, 10
parse_number:				; parsing number
	mov edx, 0			; push every digit to stack
	div ebx
	add edx, '0'
	push edx
	mov ecx, 1
	add [lenn], ecx
	cmp eax, 0
	jz print_num
	mov edx, eax
	jmp parse_number
print_num:				; print number from stack
	mov ebx, 1			;if need in print space or sign do it
	cmp [space], ebx
	jz print_space
end_psp:
	jmp print_sign
end_ps:					; align right
	jmp align_right
end_alignr:				; while current char from stack not equal -1, print it
	pop ecx
	cmp ecx, -1
	jz end_print_num
	mov eax, [myout]
	mov [eax], ecx
	mov eax, 1
	add [myout], eax
	jmp end_ps
end_print_num:
	jmp align_left
end_alignl:				; move esi to next parameter
	add esi, 4	
	jmp n_char

parameter_d:				; parse int
	add edi, 1
	mov eax, [esi]
	jmp print_number
	
parameter_u:				; parse unsigned int
	add edi, 1
	mov eax, [esi]
	jmp print_number
	
parameter_i:				; parse int
	add edi, 1
	mov eax, [esi]
	jmp print_number

parameter_ll:				; parse long long
	add edi, 2
	mov eax, [esi]
	add esi, 4
	mov edx, [esi]	
	mov ecx, 1000000000
	div ecx
	mov ecx, eax
	mov eax, edx	
	cmp eax, 0
	jg positivel
	neg eax
positivel:	
	push -1
	mov ebx, 10
parse_numberl:
	mov edx, 0
	div ebx
	push edx
	cmp eax, 0
	jz pnl
	mov edx, eax
	jmp parse_numberl
pnl:
	mov eax, ecx
	mov ecx, 0
	cmp eax, 0
	jnz parse_numberl
	mov eax, [esi]
	cmp eax, 0
	jg print_num
	mov ecx, '-'
	mov eax, [myout]
	mov [eax], ecx
	mov eax, 1
	add [myout], eax
	jmp print_num
	
; OUT - pointer to out 4 bit
section .bss
myout:		resq 1
sign:		resq 1
space:		resq 1
zero:		resq 1
minus:		resq 1
length:		resq 1
lenn:		resq 1
per:		resq 1
