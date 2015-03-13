section .text

udiv10:
        ; edx:eax - the number
        mov ecx, eax
        mov eax, edx
        xor edx, edx
        div ebx
        xchg eax, ecx
        div ebx
        xchg ecx, edx

        ; ecx - remainder
        ; edx:eax - quotient
        ret

global ulltoa
ulltoa:
        push ebp
        mov ebp, esp

        push ebx
        push ecx
        mov ebx, 10
        mov eax, [ebp + 8]
        mov edx, [ebp + 12]
        mov edi, [ebp + 16]
.move:
        inc edi
        call udiv10
        test edx, edx
        jnz .move
        test eax, eax
        jnz .move
        mov byte [edi], 0
        mov eax, [ebp + 8]
        mov edx, [ebp + 12]
.put:
        dec edi
        call udiv10
        add cl, '0'
        mov byte [edi], cl
        test edx, edx
        jnz .put
        test eax, eax
        jnz .put

        pop ecx
        pop ebx
        mov esp, ebp
        pop ebp
        ret

global ullformat
ullformat:
        push ebp
        mov ebp, esp

        push eax
        push ebx
        push ecx
        push edx
        xor ebx, ebx
        xor ecx, ecx
        mov esi, [ebp + 8]
        mov edi, [ebp + 12]

        inc esi
.flags:
        lodsb
        cmp al, '+'
        je ..@plus
        cmp al, ' '
        je ..@space
        cmp al, '-'
        je ..@minus
        cmp al, '0'
        jne .width
        or bl, ZERO_ALIGN
        jmp .flags
..@plus:
        or bl, PLUS
        jmp .flags
..@space:
        or bl, SPACE_SIGN
        jmp .flags
..@minus:
        or bl, ALIGN_LEFT
        jmp .flags
.width:
        cmp al, '9'
        jg .size
        cmp al, '0'
        jl .size
        sub al, '0'
        shl bh, 1
        mov cl, bh
        shl cl, 2
        add bh, cl
        add bh, al
        lodsb
        jmp .width
.size:
        cmp al, 'l'
        jne .type
        ; lodsb
        ; cmp al, 'l'
        ; if invalid, the whole thing is
        or bl, LONG_LONG
        inc esi
        lodsb
.type:
        cmp al, '%'
        jne ..@aNumber
        mov edi, [ebp + 12]
        stosb
        jmp .exit
..@aNumber
        ; cmp al, 'i'
        ; je .signed
        ; cmp al, 'd'
        ; je .signed
        ; cmp al, 'u'
        ; if invalid, the whole thing is
        mov eax, [ebp + 16]
        test bl, LONG_LONG
        jnz ..@longLong
        xor edx, edx
        jmp .printUll
..@longLong:
        mov edx, [ebp + 20]
.printUll:
        test bl, PLUS
        jz ..@spaceSignUll
        mov byte [edi], '+'
        inc edi
        jmp ..@doPrintUll
..@spaceSignUll:
        test bl, SPACE_SIGN
        jz ..@doPrintUll
        mov byte [edi], ' '
        inc edi
..@doPrintUll:
        push edi
        push edx
        push eax
        call ulltoa
        add esp, 12
        jmp .align
.align:
        test bl, ALIGN_LEFT
        jz ..@alignRight
        jmp .exit
..@alignRight:
        mov esi, [ebp + 12]
        test bl, ZERO_ALIGN
        jz ..@doTheJob
        test bl, ALWAYS_SIGN
        jz ..@doTheJob
        inc esi
        test bh, bh
        jz ..@doTheJob
        dec bh
..@doTheJob:
        mov edi, esi
        xor al, al
        mov cl, bh
        cld
        repne scasb
        mov esi, edi
        add edi, ecx
        sub bh, cl
        mov cl, bh
        inc cl
        std
        rep movsb
        mov ecx, edi
        sub ecx, esi
        test bl, ZERO_ALIGN
        jz ..@spaceAlign
        mov al, '0'
        jmp ..@doClean
..@spaceAlign:
        mov al, ' '
..@doClean:
        rep stosb
.exit:
        pop edx
        pop ecx
        pop ebx
        pop eax
        mov esp, ebp
        pop ebp
        ret

PLUS equ 1
SPACE_SIGN equ 2
ALWAYS_SIGN equ PLUS | SPACE_SIGN
ALIGN_LEFT equ 4
ZERO_ALIGN equ 8
LONG_LONG equ 16
SIGNED equ 32
