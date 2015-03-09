global hw_strlen
global hw_itoa
global hw_luitoa

section .data
uint_inf    dd 0xffffffff

section .text
; hw_strlen(const char *)
; returns string's length (result is written to eax according to cdecl)
hw_strlen:
    push ebp
    mov ebp, esp
    push edi
    mov edi, [esp + 12]
    
    mov edx, edi
    xor eax, eax
    
    mov ecx, uint_inf
    
    cld
    repnz scasb         
    
    sub edi, edx            ; length can be calculated by substracting begining address from ending address
    mov eax, edi    
    dec eax                 ; minus one, because scasb made one extra operation

    pop edi
    mov esp, ebp
    pop ebp
    ret

; hw_luitoa(unsigned long long, char *)
; yasno
hw_luitoa:
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
    

    cmp eax, 0
    jne .loop
    cmp edx, 0
    jne .loop

    mov [esi], word 0
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
    cmp edi, 0
    jg .loop

    mov [esi], word 0
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
    
    mov [esi], word '-'
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
