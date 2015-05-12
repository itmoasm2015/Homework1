global hw_sprintf

section .text

FLAG_PARSED_CORRECT     equ     1 << 0
FLAG_PLUS               equ     1 << 1
FLAG_SPACE              equ     1 << 2
FLAG_MINUS              equ     1 << 3
FLAG_ZERO               equ     1 << 4
FLAG_IS_LONG            equ     1 << 5
FLAG_IS_UNSIGNED        equ     1 << 6

;main function
hw_sprintf:
    push ebp
    lea ebp, [esp + 8] ;initial stack pointer
    push eax
    push ebx
    push ecx
    push edx

    mov ecx, [ebp] ;start of result string
    mov edx, [ebp + 4] ;start of format string
    lea ebp, [ebp + 8] ;now ebp is first argument

    ;iterating format string
    .loop1
        mov al, [edx] ;current byte
        test al, al
        jz .endLoop1 ;zero -> end of string

        call parse

        test bl, FLAG_PARSED_CORRECT
        jnz .printingNumber
        jmp .printSymbol
    .printingNumber
        ; esi:edi -- number to print
        test bl, FLAG_IS_LONG
        jnz .storeLong
        mov esi, [ebp]
        test esi, esi
        js .isNegative
        mov esi, 0
        jmp .isNotNegative
    .isNegative
        mov esi, -1
    .isNotNegative
        mov edi, [ebp]
        add ebp, 4
        jmp .numberStored
    .storeLong
        mov esi, [ebp + 4]
        mov edi, [ebp]
        add ebp, 8
    .numberStored
        call printInt
        jmp .loop1

    .printSecondSymbol
        inc edx
        jmp .printSymbol
    .printSymbol
        mov al, [edx]
        mov [ecx], al
        add ecx, 1
        add edx, 1
        jmp .loop1
    .endLoop1
    mov byte [ecx], 0
    inc ecx

    pop edx
    pop ecx
    pop ebx
    pop eax
    pop ebp
    ret


; esi:edi -- number to print
; number will be printed starting from ecx
; number is considered to be unsigned
printInt
    push ebp
    push eax
    push ebx
    push edx
    mov ebp, esp

    mov ebx, 10
    test esi, esi
    jns .isPositive
        not esi
        not edi
        add edi, 1
        adc esi, 0
        mov byte [ecx], '-'
        inc ecx
.isPositive
    test edi, edi
    jnz .printNumber
    test esi, esi
    jnz .printNumber
    mov byte [ecx], '0'
    inc ecx
    jmp .reverseLoopEnd
    
    ;non-zero
    .printNumber
        mov eax, esi
        mov edx, 0
        div ebx
        mov esi, eax
        mov eax, edi
        div ebx
        
        dec esp
        mov [esp], dl
        add byte [esp], '0'
        ;mov [ecx], edx
        ;add byte [ecx], '0'
        ;inc ecx
        mov edi, eax

        test esi, esi
        jnz .printNumber
        test edi, edi
        jnz .printNumber
        jmp .endPrintingNumber

    .endPrintingNumber

    .reverseLoop
        cmp esp, ebp
        je .reverseLoopEnd
        mov bl, [esp]
        inc esp
        mov [ecx], bl
        inc ecx
        jmp .reverseLoop
    .reverseLoopEnd

    pop edx
    pop ebx
    pop eax
    pop ebp
    ret

;start parsing from edx
;return bl as flags
;return esi as minimal length
;edx will change
parse
    push eax
    push edx
    push edi
    push ebp
    mov ebp, edx

    mov bl, 0
    
    mov al, [edx]
    cmp al, '%'
    jne .getTypeEnd
    inc edx

.getFlags
    mov al, [edx]
    cmp al, '+'
    jne .notPlus
    or bl, FLAG_PLUS
    jmp .getFlagsContinue
.notPlus
    cmp al, ' '
    jne .notSpace
    or bl, FLAG_SPACE
    jmp .getFlagsContinue
.notSpace
    cmp al, '-'
    jne .notMinus
    or bl, FLAG_MINUS
    jmp .getFlagsContinue
.notMinus
    cmp al, '0'
    jne .notFlag
    or bl, FLAG_ZERO
    jmp .getFlagsContinue
.notFlag
    jmp .getFlagsEnd
.getFlagsContinue
    inc edx
    jmp .getFlags
.getFlagsEnd
    
    mov eax, 0
    mov edi, 10
.getLength
    mov bh, [edx]
    cmp bh, '0'
    jl .getLengthEnd
    cmp bh, '9'
    jg .getLengthEnd
    
    push edx
    mul edi
    pop edx
    sub bh, '0'
    add al, bh
    adc ah, 0
    inc edx
    jmp .getLength
.getLengthEnd
    mov esi, eax    

    mov al, [edx]
    cmp al, 'l'
    jne .getType
    mov al, [edx + 1]
    jne .getType
    add edx, 2
    or bl, FLAG_IS_LONG    

.getType
    mov al, [edx]
    cmp al, 'i'
    jne .isNotI
    or bl, FLAG_PARSED_CORRECT
    inc edx
    jmp .getTypeEnd 
.isNotI
    cmp al, 'd'
    jne .isNotD
    or bl, FLAG_PARSED_CORRECT
    inc edx
    jmp .getTypeEnd
.isNotD
    cmp al, 'u'
    jne .getTypeEnd
    or bl, FLAG_PARSED_CORRECT
    or bl, FLAG_IS_UNSIGNED
    inc edx
    jmp .getTypeEnd    
.getTypeEnd

    test bl, FLAG_PARSED_CORRECT
    jnz .parseOk
    mov eax, ebp
    mov bh, [ebp]
    cmp bh, '%'
    jne .parseEnd
    mov bh, [ebp + 1]
    cmp bh, '%'
    jne .parseEnd
    inc eax
    jmp .parseEnd
.parseOk
    mov eax, edx
.parseEnd

    pop ebp
    pop edi
    pop edx
    mov edx, eax
    pop eax
    ret
