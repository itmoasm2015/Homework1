global itoa

section .text

    ; converts int to string
    ; 
    ; @param n the int to be converted
    ; @param out pointer to char* for string
    ; @return EAX pointer to the string
    itoa:
        push ebp
        push esi
        push edi
        push ebx
        mov eax, [esp + 20]      ; n
        mov ebx, [esp + 24]      ; out
        mov ecx, eax
        and ecx, 0x80000000      ; if highest bit is true
        jz .to_decimal_str
        ; convert from two's compliment & write '-' to out
        mov byte [ebx], '-'
        inc ebx
        not eax
        inc eax
    ; write decimal string to stack
    .to_decimal_str:
        mov ecx, 10
        mov [esp], byte 0 ; end of string
        dec esp
        .loop:
            xor edx, edx
            div ecx
            add edx, '0'
            mov byte [esp], dl
            dec esp
            cmp eax, 0
            jne .loop

    ; read characters in back order from stack & write to output
        inc esp
        mov dl, byte [esp]
        .loop1:
            mov byte [ebx], dl
            inc ebx
            inc esp
            mov dl, byte[esp]
            cmp dl, 0
            jne .loop1

        pop ebx
        pop edi
        pop esi
        pop ebp
        ret


