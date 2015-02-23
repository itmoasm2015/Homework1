global hw_sprintf

section .text

FLAG_SIGN_BIT equ 1<<0
TYPE_BIT equ 1<<1
SIZE_BIT equ 1<<2
SIGN_BIT equ 1<<7

;
;
itoa:
    ret

hw_sprintf:
    xor cl, cl
    mov [ebx], cl

    test al, [TYPE_BIT]
    jnz .sign_done;if %u - without sign

    mov cl, [esp]
    cmp cl, [SIGN_BIT]
    mov ecx, 0
    jnae .minus_sign;if number is negative
    jmp  .check_flag_sign;else

    .minus_sign
        mov cl, '-'
        mov [ebx], cl;store sign
        mov cl, [SIGN_BIT]
        xor [ebx], cl;unset sign bit
        jmp .sign_done

    .check_flag_sign
        test al, [SIGN_BIT]
        jz .sign_done;flag + doesn't set
        mov cl, '+'
        mov [ebx], cl
        jmp .sign_done

    .sign_done
    mov ecx, 1
    mov esi, 10

    test al, [SIZE_BIT]
    jz .is32bit_number;if number is 32 bit
    jmp .is64bit_number

    .is32bit_number
        xor edx, edx
        mov eax, [esp]
        add esp, 4
        jmp .size_done

    .is64bit_number
        mov edx, [esp]
        add esp, 4
        mov eax, [esp]
        add esp, 4
        jmp .size_done

    .size_done

    .loop
        mov ebp, edx;ebp - storage of edx (r8)
        mov edi, eax;edi - storage of eax (r9)

        xor edx, edx;div 64 bit number
        mov eax, ebp 
        div esi
        mov ebp, eax
        mov eax, edi
        div esi
        mov edi, eax

        add edx, '0';store digit
        mov [ebx + ecx], edx
        inc ecx

        mov edx, ebp;if equal 0
        mov eax, edi
        or ebp, edi
        cmp ebp, 0
        jnz .loop;while number doesn't eq 0
    dec ecx
    mov eax, ecx
    ret

;section .bss
    ;numBuffer: resb 22
