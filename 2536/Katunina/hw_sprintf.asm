section .text

; edx:eax/ten
; remainder in ecx
divide:  
    mov ecx, eax
    mov eax, edx
    xor edx, edx
    div ebx
    xchg eax, ecx
    div ebx
    xchg ecx, edx
    ret
    
;for printing ulonglong
ulltodec: 
    push ebp
    mov ebp, esp
    push ebx
    mov ebx, 10
    ;  edx:eax - number
    ;  edi - destination
    mov eax, [ebp + 8]
    mov edx, [ebp + 12]
    mov edi, [ebp + 16]
    
         ; determine the length of number and transfer edi to the end
        .transfer:
            inc edi
            call divide
            test edx, edx
            jnz .transfer
            test eax, eax
            jnz .transfer
            mov byte [edi], 0 ; end of number is here
            mov eax, [ebp + 8]
            mov edx, [ebp + 12]
        
        ;print the number    
        .push:
            dec edi
            call divide
            add cl, '0'
            mov byte [edi], cl
            test edx, edx
            jnz .push
            test eax, eax
            jnz .push
            pop ebx
            mov esp, ebp
            pop ebp
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
        or bl, ALIGN_ZERO
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
        
        ..@number:
            mov bh, al
            mov eax, [esp]    
            lea edx, [eax + 4] 
            ; for loading lower part of number
            mov eax, [eax]    
            test bl, LL
            jz ..@notLong
            ; the higher part is on the stack
            mov edx, [edx] 
            jmp ..@signed? 
  
        ..@notLong:
            xor edx, edx 
                      
        ..@signed?:
            ; bh contains character
            cmp bh, 'd'
            je .printS
            cmp bh, 'i'
            je .printS
            cmp bh, 'u'
            jne .invalidSeq
            
    .printUll:
        test bl, PLUS
        jz ..@spaceSignUll
        mov byte [edi], '+'
        inc edi
        jmp .align
            
        ..@spaceSignUll:
            test bl, SPACE
            jz .align
            mov byte [edi], ' '
            inc edi
            jmp .align
            
    .printS:
        cmp edx, 0
        jg ..@printPlus
        jnz ..@printMinus
        cmp eax, 0
        jge ..@printPlus
        
        ..@printMinus:
            or bl, PLUS
            mov byte [edi], '-'
            inc edi
            ;now printing abs of number
            not eax
            inc eax
            test bl, LL
            jz .align
            not edx
            adc edx, 0
            jmp .align   
            
        ..@printPlus:
            test bl, PLUS
            jz ..@printSpace
            mov byte [edi], '+'
            inc edi
            jmp .align
            
        ..@printSpace:
            test bl, SPACE
            jz .align
            mov byte [edi], ' '
            inc edi
            
    .align:
        push ecx
        push edi
        push edx
        push eax
        call ulltodec
        add esp, 12
        pop ecx
        or bl, PROCEED
        ;align the number
        test bl, ALIGN_LEFT
        jz ..@alignRight
        ;left aligning
        mov edi, [esp + 4]
        cld
        repnz scasb
        jne .exit
        dec edi
        inc ecx
        mov al, ' '
        rep stosb
        mov byte [edi], 0
        jmp .exit 
        
        ..@alignRight:          
            mov edx, esi
            inc ecx
            mov esi, [esp + 4]
            ; if empty space is filled with 0, sign should be placed at the beginning
            test bl, ALIGN_ZERO
            jz ..@continue
            test bl, ALWAYS
            jz ..@continue
            dec ecx
            inc esi
            
        ..@continue:
            ;save width
            push ecx 
            mov edi, esi      
            cld
            repnz scasb
            mov esi, edi
            ;edi  to the end
            add edi, ecx
            neg ecx
            add ecx, [esp]
            add esp, 4
            inc ecx
            ; copy to the right
            std
            rep movsb
            mov ecx, edi
            sub ecx, esi
            mov esi, edx
            ; blank character
            test bl, ALIGN_ZERO
            jz ..@spaceAlign
            mov al, '0'
            jmp ..@clean
            
            ..@spaceAlign:
                mov al, ' '
                
            ..@clean:
                rep stosb
                mov edi, [esp + 4]
                jmp .exit
                
    .invalidSeq:
        mov edi, [esp + 4]
        mov esi, [esp + 8]
       
        mov byte [edi], '%'
        mov byte [edi + 1], 0
        inc edi
            
    .exit:
        ;arg is consumed => ebx to the right
        pop ebx
        mov cl, bl
        test cl, PROCEED
        jz ..@jumpBack
        add ebx, 4
        test cl, LL
        jz ..@jumpBack
        add ebx, 4
            
        ..@jumpBack:
            mov esp, ebp
            pop ebp
            ret
                         
global hw_sprintf

hw_sprintf:

    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx
    mov edi, [ebp + 8]
    mov esi, [ebp + 12]
    ;for var args
    lea ebx, [ebp + 16]
    
    .loop:
        lodsb
        test al, al
        jz .quit 
        cmp al, '%'
        jne .print
        call format
        mov ecx, 0x7fffffff
        cld
        xor al, al
        repne scasb
        dec edi
        jmp .loop
        
    .print:
        stosb
        jmp .loop
            
    .quit:
        mov byte [edi], 0
        pop ebx
        pop edi
        pop esi
        mov esp, ebp
        pop ebp
        ret

        
PROCEED equ 64; arg was consumed
SPACE equ 2; " " instead of "+"
PLUS equ 1 ; without spaces     
SIGNED equ 32   ;signed number
ALIGN_LEFT equ 4 ;left aligning
ALIGN_ZERO equ 8 ;zeroes filling
ALWAYS equ PLUS | SPACE; printing sign
LL equ 16 ;long long

                    