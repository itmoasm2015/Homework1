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
                    