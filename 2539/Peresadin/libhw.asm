global hw_sprintf

section .text

FLAG_SIGN_BIT equ 1<<0
TYPE_BIT equ 1<<1
SIGN_MASK equ 1<<7

;
;
itoa:
    ret

hw_sprintf:
    mov cl, [esp]
    cmp cl, [SIGN_MASK]
    xor ecx, ecx

    jnae .minus_sign
    jmp  .check_flag_sign

    .minus_sign
        mov cl, '-'
        mov [ebx], cl
        mov cl, [SIGN_MASK]
        xor [ebx], cl
        xor ecx, ecx
        jmp .sign_done

    .check_flag_sign
        ;//TODO write
    
    .sign_done
    inc ecx
    mov esi, 10

    mov dword edx, [esp]
    add esp, 4
    mov dword eax, [esp]
    add esp, 4
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
