global hw_itoa
global hw_ulltoa
global hw_lltoa
global hW_sprintf

hw_sprintf:
	
hw_lltoa:
	push	ebp
	mov		ebp, esp
	push	esi
	push	ebx

	mov		eax, [esp + 16]
	mov		edx, [esp + 20]
	mov		esi, [esp + 24]
	xor		ebx, ebx
	
	cmp		edx, 0
	jge		.skipsign
	
	not		edx	; bit magic for negation number,
	not		eax
	add		eax, 1
	adc		edx, 0
	
	mov		ebx, 1

	mov		[esi], byte '-'
	inc		esi

.skipsign
	
	push	esi
	push	edx
	push	eax
	call	hw_ulltoa

	add		eax, ebx

	pop		ebx
	pop		esi
	mov		esp, ebp
	pop		ebp
	ret

; hw_luitoa(unsigned long long, char *)
; writes string representation of the first @param to second @param
; return length of string representation of the first @param
hw_ulltoa:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push ebx

    mov eax, [esp + 20]
    mov edx, [esp + 24]
    mov esi, [esp + 28]
    mov ecx, 10

.loop: ; current number - (edx:eax)
        ; edx - high_half
        ; eax - low_half
    mov ebx, eax
    
    mov eax, edx 
    xor edx, edx
    div ecx         ; div (0:high_half) by 10
    
    mov edi, eax
    mov eax, ebx
    div ecx         ; div (high_half_rem:low_half) by 10
    
    add edx, '0'
    mov [esi], edx
    inc esi

    mov edx, edi
    

    test eax, eax
    jne .loop
    test edx, edx
    jne .loop

    mov [esi], byte 0
    dec esi

    mov eax, [esp + 28]
    mov edi, esi
.loop2:
    mov dl, [esi]
    mov cl, [eax]
    mov [esi], cl
    mov [eax], dl
    inc eax
    dec esi
    cmp eax, esi
    jl .loop2
    
    mov eax, edi
    sub eax, [esp + 28]
    inc eax

    pop ebx
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret

; int hw_uitoa(unsigned_int, char *)
; writes string representation of unsigned int
; returns output string's length
hw_uitoa:
    push ebp
    mov ebp, esp
    push edi
    push esi

    mov edi, [esp + 16]
    mov esi, [esp + 20]

.loop:
    xor edx, edx
    mov eax, edi
    mov ecx, 10
    div ecx
    add edx, '0'
    mov [esi], edx
    inc esi
    mov edi, eax
    test edi, edi
    jg .loop

    mov [esi], byte 0
    dec esi

    mov eax, [esp + 20]
    mov edi, esi
.loop2:
    mov dl, [esi]
    mov cl, [eax]
    mov [esi], cl
    mov [eax], dl
    inc eax
    dec esi
    cmp eax, esi
    jl .loop2
    
    mov eax, edi
    sub eax, [esp + 20]
    inc eax

    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret

; int hw_itoa(int, char *)
; writes string representation of signed int 
; returns length of output string
hw_itoa:
    push ebp
    mov ebp, esp
    push edi
    push esi
    push ebx
    
    mov edx, [esp + 20]      ; int
    mov esi, [esp + 24]      ; char *
    xor ebx, ebx

    cmp edx, 0
    jge .skip_sign
    
    mov [esi], byte '-'
    inc esi
    neg edx
    inc ebx

.skip_sign:
    push esi
    push edx
    call hw_uitoa
    add eax, ebx

    pop ebx
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret
