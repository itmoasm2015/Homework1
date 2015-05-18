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
	mov ecx, [esp + 20]		; add out pointer to out
	mov [myout], ecx		;
	mov edi, [esp + 24]		; add format pointer to edi
	mov esi, esp			;
	add esi, 28			; add pointer to current parameter
	jmp parse_str
endall:
	pop ebx
	pop esi
	pop edi
	pop ebp
	ret

; parse string
; if cureent symbol is %, go to parse type
parse_str:
	mov byte al, [edi]		; put current symbol to al
	cmp byte al, '%'		; if s[i] == %
	jz parse_type
pr:
	mov ecx, [myout]		;
	mov [ecx], byte al		; write to out 1 char
	mov ecx, 1			;
	add [myout], ecx		; 
	add edi, 1			; next char
n_char:
	cmp byte al, 0			; if end of string return
	jnz parse_str
	jmp endall 

parse_type:
	mov ebx, 0			
	mov [sign], ebx			; set fields zero
	mov [space], ebx		
	mov [minus], ebx		
	mov [zero], ebx			
	mov [length], ebx		
	mov [lenn], ebx			
	mov [per], edi			
	mov [flag_u], ebx
	mov [flag_i], ebx
	mov [flag_d], ebx
	mov [flag_ll], ebx
	mov [sm], ebx
parse:
	add edi, 1			; next char
	mov byte al, [edi]		;
	cmp byte al, 0			; if end of string return
	jz endall
	cmp byte al, '+'		;
	jz set_sign			; set flag +
	cmp byte al, ' '		;
	jz set_space			; set flag space
	cmp byte al, '-'		;
	jz set_minus			; set flag -
	cmp byte al, '0'		;
	jz set_zero			; set flag 0
width:
	cmp byte al, '1'		;
	jl llsize			
	cmp byte al, '9'		;
	jle set_length			; set length
llsize:
	cmp byte al, 'l'
	jz parameter_ll			; type is ll
types:
	cmp byte al, 'd'
	jz parameter_d			; type is d
	cmp byte al, 'u'
	jz parameter_u			; type is u
	cmp byte al, 'i'
	jz parameter_i			; type is i
	cmp byte al, '%'
	jz parametr_pr			; type is %
incorrect:
	mov edi, [per]			; if incorrect flags and type print expression
	mov byte al, [edi]
	jmp pr

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
.sl:
	sub byte cl, '0'
	mov eax, [length]
	mov ebx, 10			; multiply ebx to 10
	mul ebx
	mov [length], eax
	add [length], byte cl		; add length next digit
	add edi, 1
	mov byte cl, [edi]
	cmp byte cl, '0'
	jl .esl
	cmp byte cl, '9'
	jle .sl
.esl:
;	sub edi, 1
	mov byte al, [edi]
	jmp llsize
	 	 
print_sign:
	mov ebx, 1
	cmp [sign], ebx			; if no need sign return
	jnz end_ps
	mov eax, [esi]
	mov ecx, '-'			; sign is -
	cmp eax, 0
	jl .add_sign
	mov ecx, '+'			; if eax > 0 sign is +
.add_sign:
	push ecx
	mov ebx, 1
	add [lenn], ebx			; add 1 to lenn, because we printed sign
	mov ebx, 0
	mov [space], ebx
	jmp end_ps

print_space:				; if need a spaces push it to stack
	mov ebx, 1
	cmp [space], ebx
	jnz end_psp
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
	jge end_alignl
	mov ebx, ' '
	mov eax, [myout]		; print space
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
	mov ebx, '0'
	cmp [zero], eax			; check flags zero
	jz .ali
	mov ebx, ' '			; print space
.ali:
	push ebx
	add [lenn], eax
	jmp align_right

print_number:
	push -1				;push start symbol to stack
	mov eax, [esi]
	mov ebx, 1
	cmp [flag_u], ebx		; if type is u, we shouldn't think about sign
	jz positive
	cmp eax, 0
	jge positive
	mov ebx, 1
	mov [sign], ebx			; set sign = 1, it's equal '-'
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
	mov ebx, 0
	cmp [length], ebx
	jnz .len_not_zero
	mov ebx, [lenn]
	mov [length], ebx
.len_not_zero:
	mov ebx, 1			; if need to print spaces or sign do it
	cmp [flag_u], ebx
	jnz .ss
	mov ebx, 0			; if type is unsigned no need to print spase or sign
	mov [space], ebx
	mov [sign], ebx
.ss:
	mov ebx, 1
	cmp [zero], ebx			; if should align ' ' push sign and spacebefore
	jnz pps
	mov ebx, [sign]
	add ebx, [space]
	cmp ebx, 1
	jle .ss3
	mov ebx, 1
.ss3:
	add [lenn], ebx			; if should align '0' push zeros before sign and spaces
	mov [tmp], ebx			; remember count of position to sign and space
	mov ecx, 1
	mov [sm], ecx
	jmp align_right			
retl:
	mov ebx, [tmp]
	sub [lenn], ebx			; restore positions to sign ans space
pps:
	jmp print_sign
end_ps:
	jmp print_space
end_psp:
	mov ecx, 0
	mov [sm], ecx
	jmp align_right
end_alignr:				; while current char from stack not equal -1, print it
	mov ecx, 1
	cmp [sm], ecx
	jz retl
	pop ecx
	cmp ecx, -1
	jz end_print_num
	mov eax, [myout]
	mov [eax], ecx
	mov eax, 1
	add [myout], eax
	jmp end_alignr
end_print_num:
	jmp align_left			; check align left
end_alignl:				; move esi to next parameter
	add esi, 4	
	jmp n_char

parameter_d:				; parse int
	add edi, 1
	mov eax, 1
	mov [flag_d], eax		; set flag int
	cmp [flag_ll], eax		; parse long long int, if flag_ll = 1
	jz parse_ll
	jmp print_number		; go to parse int
	
parameter_u:				; parse unsigned int
	add edi, 1
	mov eax, 1
	mov [flag_u], eax
	cmp [flag_ll], eax		; parse unsigned long long int, if flag_ll = 1
	jz parse_ll
	jmp print_number		; go to parse unsigned int
	
parameter_i:				; parse int
	add edi, 1
	mov eax, 1
	mov [flag_i], eax
	cmp [flag_ll], eax		; parse long long int, if flag_ll = 1
	jz parse_ll
	jmp print_number		; go to parse int

parameter_ll:
	add edi, 1
	mov byte al, [edi]
	cmp byte al, 'l'
	jnz incorrect
	add edi, 1
	mov eax, 1
	mov [flag_ll], eax		; set long long flag = 1
	mov byte al, [edi]
	jmp types			; go to read type

parametr_pr:
	add edi, 1
	mov eax, 0
	mov byte al, '%'		; print type %
	mov ebx, [myout]
	mov [ebx], eax
	mov eax, 1
	add [myout], eax
	jmp parse_str
	
	
parse_ll:				; parse long long
	mov eax, 1
	mov ecx, [esi]
	add esi, 4
	mov ebx, [esi]
	cmp [flag_u], eax		; if we parse unsigned type, we won't want to think about sign
	jz .positivel2
	cmp ebx, 0
	jge .positivel2
	not ecx				; take absolutely value	
	mov eax, 1
	mov [sign], eax
	not ebx
	add ecx, 1
	adc ebx, 0
.positivel2:	
	push -1	
.parse_numberl:				; high:low = ebx:ecx
	mov eax, ecx			; if high part equal 0, parse int
	cmp ebx, 0
	jz .pnl
	mov eax, ebx
	mov edx, 0
	mov ebx, 10
	div ebx				; divide 0:high to 10
	mov [tmp], eax			; save eax = 0:high / 10
	mov eax, ecx
	div ebx				; divide edx:low to 10
	add edx, '0'
	push edx			; push current symbol (edx = edx:low % 10) to stack
	mov ebx, 1
	add [lenn], ebx			; lenn++
	mov ebx, [tmp]
	mov ecx, eax			; set high = 0:high / 10, low = ((0:high % 10):low) / 10
	jmp .parse_numberl
.pnl:
	mov ecx, 0
	mov ebx, 10
	jmp parse_number		; if high part equal 0, parse int
	
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
tmp:		resq 1
flag_u:		resq 1
flag_i:		resq 1
flag_d:		resq 1
flag_ll:	resq 1
sm:		resq 1
