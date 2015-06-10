section .text

;for printing ulonglong
ulltodec: 
    push edi
    mov edi, esp
    push ebx
    mov ebx, 10
    ;  edx:eax - number
    ;  edi - destination
    mov eax, [edi + 8]
    mov edx, [edi + 12]
    mov edi, [edi + 16]
    
         ; determine the length of number and transfer edi to the end
        .transfer:
            inc edi
            call div
            test edx, edx
            jnz .transfer
            test eax, eax
            jnz .transfer
            ;end of number
            mov byte [edi], 0 
            mov eax, [edi + 8]
            mov edx, [edi + 12]
        
        ;print the number    
        .push:
            dec edi
            call div
            add cl, '0'
            mov byte [edi], cl
            test edx, edx
            jnz .push
            test eax, eax
            jnz .push
            pop ebx
            mov esp, edi
            pop edi
            ret

; edx:eax/ten
; remainder in ecx
div:  
    mov ecx, eax
    mov eax, edx
    xor edx, edx
    div ebx
    xchg eax, ecx
    div ebx
    xchg ecx, edx
    ret


;Format number base on record in $esi
format:
    push ebp
    mov ebp, esp
    push esi 
    ;needed if malformed sequence
    push edi 
    push ebx
    xor ebx, ebx
    xor ecx, ecx
    xor eax, eax
    
    ;mask will be in bl
    .flags: 
        lodsb
        cmp al, '+'
        je ..@add
        cmp al, ' '
        je ..@space
        cmp al, '-'
        je ..@sub
        cmp al, '0'
        jne .minWidth
        or bl, ZERO_ALIGN
        jmp .flags
        
         ..@sub:
                or bl, ALIGN_LEFT
                jmp .flags
         
         ..@space:
                or bl, SPACE
                jmp .flags
                       
        ..@add:
                or bl, PLUS
                jmp .flags
    
    ; minimum width will be in ecx            
    .minWidth: 
        cmp al, '9'
        jg .size
        cmp al, '0'
        jl .size
        sub al, '0'
        shl ecx, 1 
        mov edx, ecx
        shl edx, 2
        add ecx, eax
        add ecx, edx
        lodsb
        jmp .minWidth
    
    ; ll prefix ?    
    .size: 
        cmp al, 'l'
        jne .type
        lodsb
        cmp al, 'l'
        jne .invalidSeq
        or bl, LL
        lodsb
    
    ; get type        
    .type:
        cmp al, '%'
        jne ..@number
        stosb
        mov byte [edi], 0
        jmp .exit
        
        ..@number
            mov bh, al
            mov eax, [esp]    
            lea edx, [eax + 4] 
            ; for loading lower part of number
            mov eax, [eax]    
            test bl, LL
            jz ..@notL
            ; the higher part is on the stack
            mov edx, [edx] 
            jmp ..@checkSigned      
                         
global hw_sprintf

hw_sprintf:

    push edi	
    push ebx
    push ebp
    push esi
    mov edi, esp
    mov ebp, [edi + 8]
    mov ebx, [edi + 12]
    ; for var args
    lea esi, [edi + 16] 
    
    .loop:
        lodsb
        test al, al
        ; '\0'
        jz .quit
        cmp al, '%'
        jne .print
        call format
        mov ecx, 0x7fffffff
        cld
        xor al, al
        repne scasb
        dec esi
        jmp .loop
        
    .print:
        stosb
        jmp .loop
            
    .quit:
        mov byte [esi], 0
        pop esi
        pop ebp
        pop ebx
        mov esp, edi
        pop edi
        ret
                    