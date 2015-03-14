section .text

div10:
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

ulltoa:
        push ebp
        mov ebp, esp

        push ebx
        mov ebx, 10
        mov eax, [ebp + 8]
        mov edx, [ebp + 12]
        mov edi, [ebp + 16]
.move:
        inc edi
        call div10
        test edx, edx
        jnz .move
        test eax, eax
        jnz .move
        mov byte [edi], 0
        mov eax, [ebp + 8]
        mov edx, [ebp + 12]
.put:
        dec edi
        call div10
        add cl, '0'
        mov byte [edi], cl
        test edx, edx
        jnz .put
        test eax, eax
        jnz .put

        pop ebx
        mov esp, ebp
        pop ebp
        ret

ullformat:
        push ebp
        mov ebp, esp

        push esi
        push edi
        push ebx
        xor eax, eax
        xor ebx, ebx
        xor ecx, ecx
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
        shl ecx, 1
        mov edx, ecx
        shl edx, 2
        add ecx, edx
        add ecx, eax
        lodsb
        jmp .width
.size:
        cmp al, 'l'
        jne .type
        lodsb
        cmp al, 'l'
        jne .invalidSequence
        or bl, LONG_LONG
        lodsb
.type:
        cmp al, '%'
        jne ..@aNumber
        stosb
        mov byte [edi], 0
        jmp .exit
..@aNumber
        mov bh, al
        mov eax, [esp]
        lea edx, [eax + 4]
        mov eax, [eax]
        test bl, LONG_LONG
        jz ..@notLong
        mov edx, [edx]
        jmp ..@checkSigned
..@notLong:
        xor edx, edx
..@checkSigned:
        cmp bh, 'i'
        je .printSigned
        cmp bh, 'd'
        je .printSigned
        cmp bh, 'u'
        jne .invalidSequence
.printUll:
        test bl, PLUS
        jz ..@spaceSignUll
        mov byte [edi], '+'
        inc edi
        jmp .align
..@spaceSignUll:
        test bl, SPACE_SIGN
        jz .align
        mov byte [edi], ' '
        inc edi
        jmp .align
.printSigned:
        cmp edx, 0
        jg ..@printPlus
        jnz ..@printMinus
        cmp eax, 0
        jge ..@printPlus
..@printMinus:
        or bl, PLUS
        mov byte [edi], '-'
        inc edi
        neg eax
        neg edx
        jmp .align
..@printPlus:
        test bl, PLUS
        jz .align
        mov byte [edi], '+'
        inc edi
.align:
        push ecx
        push edi
        push edx
        push eax
        call ulltoa
        add esp, 12
        pop ecx
        or bl, PROCEED
        test bl, ALIGN_LEFT
        jz ..@alignRight
        mov edi, [esp + 4]
        cld
        repnz scasb
        mov al, ' '
        dec edi
        inc ecx
        rep stosb
        mov byte [edi], 0
        jmp .exit
..@alignRight:
        inc ecx
        mov edx, esi
        mov esi, [esp + 4]
        test bl, ZERO_ALIGN
        jz ..@doTheJob
        test bl, ALWAYS_SIGN
        jz ..@doTheJob
        inc esi
        dec ecx
..@doTheJob:
        mov edi, esi
        push ecx
        cld
        ; xor al, al
        repnz scasb
        mov esi, edi
        add edi, ecx
        neg ecx
        add ecx, [esp]
        add esp, 4
        inc ecx
        std
        rep movsb
        mov ecx, edi
        sub ecx, esi
        mov esi, edx
        test bl, ZERO_ALIGN
        jz ..@spaceAlign
        mov al, '0'
        jmp ..@doClean
..@spaceAlign:
        mov al, ' '
..@doClean:
        rep stosb
        jmp .exit
.invalidSequence:
        mov esi, [esp + 8]
        mov edi, [esp + 4]
        mov byte [edi], '%'
        mov byte [edi + 1], 0
        inc edi
.exit:
        mov cl, bl
        pop ebx
        test cl, PROCEED
        jz ..@jumpBack
        add ebx, 4
        test cl, LONG_LONG
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
        lea ebx, [ebp + 16]
.loop:
        lodsb
        test al, al
        jz .exit
        cmp al, '%'
        jne ..@justPrint
        call ullformat
        mov ecx, 0x7fffffff
        cld
        xor al, al
        repnz scasb
        dec edi
        jmp .loop
..@justPrint:
        stosb
        jmp .loop
.exit:
        mov byte [edi], 0
        pop ebx
        pop edi
        pop esi
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
PROCEED equ 64
