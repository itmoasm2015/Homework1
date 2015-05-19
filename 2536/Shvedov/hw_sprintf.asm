global hw_sprintf 
	
section .text
	
hw_sprintf:
        push ebp		
        mov ebp, esp
        push esi
        push edi
        push ebx
        mov edi, [ebp + 8]
        mov esi, [ebp + 12]
        lea ebx, [ebp + 16] ; indicates to the variadic arguments
.loop:
        lodsb
        test al, al
        jz .leave ; end of the C string
        cmp al, '%'
        jne ..print
        call ullformatnumber
        ; move edi to the end of output
        mov ecx, 0x7fffffff
        cld
        xor al, al
        repne scasb
        dec edi
        jmp .loop
..print:
        stosb
        jmp .loop
.leave:
        mov byte [edi], 0
        pop ebx
        pop edi
        pop esi
        mov esp, ebp
        pop ebp
        ret
	
; Format the number in accordance with record in $esi,сalled by hw_sprintf, works with registers in place.
; Not get any arguments from stack or save registers,ebx,esi and edi are used by hw_sprintf then.
ullformatnumber:
        push ebp
        mov ebp, esp
        push esi ; keep backups of all pointers to turn back
        push edi ; in case of a wrong sequence
        push ebx
        xor eax, eax
        xor ebx, ebx
        xor ecx, ecx
.banners: ; bl will hold a mask with necessary booleans
        lodsb
        cmp al, '+'
        je ..operation_plus
        cmp al, ' '
        je ..operation_space
        cmp al, '-'
        je ..operation_minus
        cmp al, '0'
        jne .min_width
        or bl, 8
        jmp .banners
..operation_space:
        or bl, 2
        jmp .banners
..operation_minus:
        or bl, 4
        jmp .banners
..operation_plus:
        or bl, 1
        jmp .banners
.size:  ; test for ll prefix
        cmp al, 'l'
        jne .type
        lodsb
        cmp al, 'l'
        jne .wrong_sequence
        or bl, 16
        lodsb
.min_width: ; ecx will hold the minimum width
        cmp al, '9'
        jg .size
        cmp al, '0'
        jl .size
        sub al, '0'
        shl ecx, 1 ; multiply ecx by 10
        mov edx, ecx
        shl edx, 2
        add ecx, edx
        add ecx, eax
        lodsb
        jmp .min_width
.type:  ; read the type of number
        cmp al, '%'
        jne ..number
        stosb
        mov byte [edi], 0
        jmp .leave
..number
        mov bh, al
        mov eax, [esp]     ; ebx was pushed here
        lea edx, [eax + 4] ; it points to the next function argument
        mov eax, [eax]     ; load the lower part of number
        test bl, 16
        jz ..check_long
        mov edx, [edx] ; the higher part is on the stack there
        jmp ..revise_signed
..check_long
        xor edx, edx ; the higher part is zero
..revise_signed:
        ; the symbol is in bh,in means eax is invaded
        cmp bh, 'i'
        je .sign_ullformat_print
        cmp bh, 'd'
        je .sign_ullformat_print
        cmp bh, 'u'
        jne .wrong_sequence
.ullformat_print:
        test bl, 1
        jz ..space_sign_ullformat
        mov byte [edi], '+'
        inc edi
        jmp .aline
..space_sign_ullformat:
        test bl, 2
        jz .aline
        mov byte [edi], ' '
        inc edi
        jmp .aline
.sign_ullformat_print:
        ; if the number is negative(here is first check)
        cmp edx, 0
        jg ..operation_plus_print
        jnz ..operation_minus_print
        cmp eax, 0
        jge ..operation_plus_print
..operation_minus_print:
or bl, 1 ; set the flag,in this case the sign is printed anyway
mov byte [edi], '-'
inc edi
; after print the sign,we should negate the number then and print as a positive one
not eax
inc eax
test bl, 16
jz .aline ; edx is already zero anyway
not edx
adc edx, 0
jmp .aline
..operation_plus_print:
        test bl,1
        jz ..operation_space_print ; check for space sign
        mov byte [edi], '+'
        inc edi
        jmp .aline
..operation_space_print:
        test bl, 2
        jz .aline
        mov byte [edi], ' '
        inc edi
.aline:
        ; print the number firstly
        push ecx ;
        push edi
        push edx
        push eax
        call ulltoa
        add esp, 12
        pop ecx
        or bl, 64
        ; now we should aline the number
        test bl, 4
        jz ..aline_right
        ; alining to the left
        mov edi, [esp + 4]
        cld
        repnz scasb
        jne .leave ; the last symbol was not "\0"
        dec edi
        inc ecx
        mov al, ' '
        rep stosb
        mov byte [edi], 0
        jmp .leave
..aline_space:
        mov al, ' '
..clean:
        rep stosb
        mov edi, [esp + 4]
        jmp .leave
..aline_right:
        inc ecx
        mov edx, esi
        mov esi, [esp + 4]
        ; if the empty space is filled with 0,the sign should be placed at the beginning
        test bl, 8
        jz ..move_to_end
        test bl, 1 | 2
        jz ..move_to_end
        ; leave the sign at the beginning
        inc esi
        dec ecx
..move_to_end:
        ; move to the end of number
        mov edi, esi
        push ecx ; backup the width value
        cld
        repnz scasb
        ; move edi to the final place
        mov esi, edi
        add edi, ecx
        neg ecx
        add ecx, [esp]
        add esp, 4
        inc ecx
        ; move backwards,it means copy the number to the right
        std
        rep movsb
        ; fill the space(remaining) with empty symbols,firstly we get length of space(remaining)
        mov ecx, edi
        sub ecx, esi
        mov esi, edx
        ; determine the empty symbols
        test bl, 8
        jz ..aline_space
        mov al, '0'
        jmp ..clean
.wrong_sequence:
        ; return esi to the position next to '%'(well,print '%' as if it was not a special reason)
        mov esi, [esp + 8]
        mov edi, [esp + 4]
        mov byte [edi], '%'
        mov byte [edi + 1], 0
        inc edi
.leave:
        ; check if the argument is consumed,after that we should move ebx to the right(if condition is true)
        mov cl, bl
        pop ebx
        test cl, 64
        jz ..jump_back
        add ebx, 4
        test cl, 16
        jz ..jump_back
        add ebx, 4
..jump_back:
        mov esp, ebp
        pop ebp
        ret
	
divide10:  ; divide edx:eax by 10,ecx is a remainder
        mov ecx, eax
        mov eax, edx
        xor edx, edx
        div ebx
        xchg eax, ecx
        div ebx
        xchg ecx, edx
        ret

; Print an unsigned long long in decimal resentation.There we don't have any information about format.
ulltoa: push ebp
        mov ebp, esp
        push ebx
        mov ebx, 10
        ; edx:eax is the number,edi is the destination
        mov eax, [ebp + 8]
        mov edx, [ebp + 12]
        mov edi, [ebp + 16]
.shift: ; determine the length of number,move edi to the end
        inc edi
        call divide10
        test edx, edx
        jnz .shift
        test eax, eax
        jnz .shift
        mov byte [edi], 0
        mov eax, [ebp + 8]
        mov edx, [ebp + 12]
.place:   ; print the number moving backwards
        dec edi
        call divide10
        add cl, '0'
        mov byte [edi], cl
        test edx, edx
        jnz .place
        test eax, eax
        jnz .place
        pop ebx
        mov esp, ebp
        pop ebp
        ret
