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
	mov ecx, [esp + 8]		;add pointer to out to out
	mov [myout], ecx
	mov edi, [esp + 12]		;add pointer to format to edi
	mov esi, esp
	add esi, 16
	jmp print_str
endall:
	pop ebp
	ret

print_str:
	mov byte al, [edi]
	cmp byte al, '%'		; if s[i] == %
	jz parse
	mov ecx, [myout]		
	mov [ecx], byte al		; write to out 1 char
	mov ecx, 1
	add [myout], ecx		; next char
	add edi, 1			;
n_char:
	cmp byte al, 0			;if end of string return
	jnz print_str
	jmp endall 

parse:
	add edi, 1
	mov byte al, [edi]
	cmp byte al, '+'
	jz set_sign
	cmp byte al, ' '
	jz set_space
	cmp byte al, '-'
	jz set_minus
	cmp byte al, '0'
	jz set_zero
	cmp byte al, '1'
	jg types
	cmp byte al, '9'
	jl set_length
types:
	cmp byte al, 'd'
	jz parameter_d
	cmp byte al, 'u'
	jz parameter_u
	cmp byte al, 'i'
	jz parameter_i
	cmp byte al, 'l'
	jz parameter_ll

set_sign:
	mov ecx, [sign]
	mov ebx, 1
	mov [ecx], ebx
	jmp parse 
	
set_space:
	mov ecx, [space]
	mov ebx, 1
	mov [ecx], ebx
	jmp parse 

set_minus:
	mov ecx, [minus]
	mov ebx, 1
	mov [ecx], ebx
	jmp parse 

set_zero:
	mov ecx, [zero]
	mov ebx, 1
	mov [ecx], ebx
	jmp parse

set_length:
	mov ecx, [length]
	mov ebx, 0
	mov [ecx], ebx
sl:
	sub byte al, '0'
	mov eax, [ecx]
	mov ebx, 10	
	mul ebx
	mov [ecx], eax
	add [ecx], byte al
	add edi, 1
	mov byte al, [edi]
	cmp byte al, '0'
	jl esl
	cmp byte al, '9'
	jg sl
esl:
	sub edi, 1
	jmp parse
	 	 
print_sign:	
	mov ecx, '-'
	cmp eax, 0
	jl add_sign
	mov ebx, [myout]
	mov eax, 1	
	cmp [ebx], eax
	jnz end_ps
	mov ecx, '+'
add_sign:
	mov ebx, [myout]
	mov [ebx], ecx
	mov ebx, 1
	add [myout], ebx
	jmp end_ps

print_number:
	jmp print_sign
end_ps:
	cmp eax, 0
	jg positive
	neg eax
positive:	
	push -1
	mov ebx, 10
parse_number:
	mov edx, 0
	div ebx
	push edx
	cmp eax, 0
	jz print_num
	mov edx, eax
	jmp parse_number
print_num:
	pop ecx
	cmp ecx, -1
	jz end_print_num
	add ecx, '0'
	mov eax, [myout]
	mov [eax], ecx
	mov eax, 1
	add [myout], eax
	jmp print_num
end_print_num:
	add esi, 4	
	jmp n_char

parameter_d:
	add edi, 1
	mov eax, [esi]
	jmp print_number
	
parameter_u:
	add edi, 1
	mov eax, [esi]
	jmp print_number

parameter_i:
	add edi, 1
	mov eax, [esi]
	jmp print_number

parameter_ll:
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
