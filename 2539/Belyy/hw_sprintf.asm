global hw_sprintf

section .text

CONTROL_FLAG_STATE  equ     1 << 8
FLAG_PLUS_STATE     equ     1 << 9
FLAG_SPACE_STATE    equ     1 << 10
FLAG_MINUS_STATE    equ     1 << 11
FLAG_ZERO_STATE     equ     1 << 12
SIZE_LONG_STATE     equ     1 << 13
UNSIGNED_STATE      equ     1 << 14
INTERN_SIGN_STATE   equ     1 << 15


; takes:
;   ESI - pointer to input buffer
; returns:
;   EBX - output integer
hw_atoi:            xor ebx, ebx
.convert_to_int:    imul ebx, 10
                    add bl, byte [esi]
                    sub bl, '0'
                    inc esi
                    cmp byte [esi], '0'
                    jl hw_sprintf.continue_no_inc
                    cmp byte [esi], '9'
                    jle .convert_to_int
                    jmp hw_sprintf.continue_no_inc


; takes:
;   EAX - state (stored in ESP + 4)
;   EBX - integer width (stored in ESP)
;   EDI - pointer to out buffer
;   EBP - pointer to cur stack arg
; uses:
;   EAX - temporary variable 1
;   EBX - length of cur stack arg
;   ECX - value of cur stack arg
;   EDX - temporary variable 2
;  [ESP] - integer width
;  [ESP + 4] - state
out32:              push eax
                    push ebx
                    xor ebx, ebx
                    mov ecx, [ebp]
                    test dword [esp + 4], UNSIGNED_STATE
                    jnz .calculate_len
                    test ecx, ecx
                    js .convert_to_uint
.calculate_len:     mov eax, -858993459
                    mul ecx
                    shr edx, 3
                    mov ecx, edx
                    inc ebx
                    test ecx, ecx
                    jnz .calculate_len
                    push .out_number
                    jmp out_left_part
.out_number:        lea edi, [edi + ebx]
                    mov ecx, [ebp]
.out_number_loop:   dec edi
                    mov byte [edi], '0'
                    mov eax, -858993459
                    mul ecx
                    shr edx, 3
                    mov ecx, edx
                    imul ecx, 10
                    mov eax, [ebp]
                    sub eax, ecx            ; eax = ecx % 10
                    add [edi], al
                    mov eax, -858993459
                    mul ecx
                    shr edx, 3
                    mov ecx, edx            ; ecx = ecx / 10
                    mov [ebp], ecx
                    test ecx, ecx
                    jnz .out_number_loop
                    lea edi, [edi + ebx]
                    push .finally
                    test dword [esp + 8], FLAG_MINUS_STATE
                    jnz out_right_spaces
                    add esp, 4
.finally:           add esp, 8
                    add ebp, 4
                    xor eax, eax
                    xor ebx, ebx
                    jmp hw_sprintf.continue

.convert_to_uint:   neg ecx
                    mov [ebp], ecx
                    or dword [esp + 4], INTERN_SIGN_STATE
                    jmp .calculate_len


; takes:
;   EAX - state (stored in ESP + 4)
;   EBX - integer width (stored in ESP)
;   EDI - pointer to out buffer
;   EBP - pointer to cur stack arg
; uses:
;   EAX - temporary variable 1
;   EBX - length of cur stack arg
;   ECX - value of cur stack arg
;   EDX - temporary variable 2
;  [ESP] - integer width
;  [ESP + 4] - state
out64:              push eax
                    push ebx
                    xor ebx, ebx
                    mov eax, [ebp]
                    mov edx, [ebp + 4]
                    mov ecx, 10
                    test dword [esp + 4], UNSIGNED_STATE
                    jnz .calculate_len
                    test edx, edx
                    js .convert_to_uint
.calculate_len:     push eax
                    mov eax, edx
                    xor edx, edx
                    div ecx
                    xchg eax, [esp]
                    div ecx
                    pop edx
                    inc ebx
                    test eax, eax
                    jnz .calculate_len
                    test edx, edx
                    jnz .calculate_len
                    push .out_number
                    jmp out_left_part
.out_number:        lea edi, [edi + ebx]
                    mov ecx, 10
.out_number_loop:   dec edi
                    mov byte [edi], '0'
                    mov eax, [ebp + 4]
                    xor edx, edx
                    div ecx
                    lea eax, [edx * 3]
                    lea eax, [eax * 2]      ; eax = 6 * (edx % 10)
                    push eax                ;     = (2^32 * edx) % 10
                    xor edx, edx
                    mov eax, [ebp]
                    div ecx
                    pop eax
                    lea eax, [eax + edx]    ; al  = (2^32 * edx + eax) % 10
                                            ;     = (edx:eax) % 10
                    mov al, [rem_table + eax]
                    add [edi], al
                    mov eax, [ebp]
                    mov edx, [ebp + 4]
                    push eax
                    mov eax, edx
                    xor edx, edx
                    div ecx
                    xchg eax, [esp]
                    div ecx
                    pop edx
                    mov [ebp], eax
                    mov [ebp + 4], edx      ; (edx:eax) = (edx:eax) / 10
                    test eax, eax
                    jnz .out_number_loop
                    test edx, edx
                    jnz .out_number_loop
.after_number:      lea edi, [edi + ebx]
                    push .finally
                    test dword [esp + 8], FLAG_MINUS_STATE
                    jnz out_right_spaces
                    add esp, 4
.finally:           add esp, 8
                    add ebp, 8
                    xor eax, eax
                    xor ebx, ebx
                    jmp hw_sprintf.continue

.convert_to_uint:   neg edx
                    neg eax
                    sbb edx, 0
                    mov [ebp], eax
                    mov [ebp + 4], edx
                    or dword [esp + 4], INTERN_SIGN_STATE
                    jmp .calculate_len

out_left_part:      sub [esp + 4], ebx
                    mov eax, [esp + 8]
                    push .after_dec
                    test eax, INTERN_SIGN_STATE
                    jnz dec_width
                    test eax, FLAG_PLUS_STATE | FLAG_SPACE_STATE
                    jnz dec_width
                    add esp, 4
.after_dec:         push .out_sign
                    test eax, FLAG_MINUS_STATE | FLAG_ZERO_STATE
                    jz out_left_spaces
                    add esp, 4
.out_sign:          push .after_sign
                    test eax, INTERN_SIGN_STATE
                    jnz out_minus
                    test eax, FLAG_PLUS_STATE
                    jnz out_plus
                    test eax, FLAG_SPACE_STATE
                    jnz out_space
                    add esp, 4
.after_sign:        push .out_number
                    test eax, FLAG_MINUS_STATE
                    jz out_zeros
                    add esp, 4
.out_number:        ret

dec_width:          dec dword [esp + 8]
                    ret

out_left_spaces:    mov ecx, [esp + 8]
.left_spaces_loop:  cmp ecx, 0
                    jle .left_finally
                    mov byte [edi], ' '
                    inc edi
                    dec ecx
                    jmp .left_spaces_loop
.left_finally:      mov dword [esp + 8], 0
                    ret

out_zeros:          mov ecx, [esp + 8]
.zeros_loop:        cmp ecx, 0
                    jle .zeros_finally
                    mov byte [edi], '0'
                    inc edi
                    dec ecx
                    jmp .zeros_loop
.zeros_finally:     ret

out_right_spaces:   mov ecx, [esp + 4]
.right_spaces_loop: cmp ecx, 0
                    jle .right_finally
                    mov byte [edi], ' '
                    inc edi
                    dec ecx
                    jmp .right_spaces_loop
.right_finally:     ret

out_minus:          mov byte [edi], '-'
                    inc edi
                    ret

out_plus:          mov byte [edi], '+'
                    inc edi
                    ret

out_space:          mov byte [edi], ' '
                    inc edi
                    ret


; void hw_sprintf(char * out, const char * format, ...)
; takes:
;   ESI - pointer to format buffer
;   EDI - pointer to out buffer
; uses:
;   EAX - state variable (flags, size and cur char)
;   EBX - integer width
;   ECX - temporary variable 1
;   EDX - temporary variable 2
;   EBP - pointer to cur stack arg
hw_sprintf:         push ebp
                    push esi
                    push edi
                    push ebx
                    mov edi, [esp + 20]     ; edi = out
                    mov esi, [esp + 24]     ; esi = format
                    lea ebp, [esp + 28]     ; ebp = head(...)
                    xor eax, eax            ; state = 0
                    xor ebx, ebx            ; width = 0
                    mov al, byte [esi]
.read_format:       cmp al, '%'
                    jne .not_percent
;; if CONTROL_FLAG bit is set, reset it and vice versa
                    xor eax, CONTROL_FLAG_STATE
.not_percent:       test eax, CONTROL_FLAG_STATE
                    jz .out_char
                    cmp al, '+'
                    je .set_plus
                    cmp al, ' '
                    je .set_space
                    cmp al, '-'
                    je .set_minus
                    cmp al, 'i'
                    je .out_int
                    cmp al, 'd'
                    je .out_int
                    cmp al, 'u'
                    je .out_uint
                    cmp al, 'l'
                    je .maybe_set_long
                    cmp al, '0'
                    je .set_zero
                    jg .maybe_read_width
.maybe_continue:    cmp al, '%'
                    jne .out_malformed
.continue:          inc esi
.continue_no_inc:   mov al, byte [esi]
                    test al, al
                    jne .read_format
                    mov byte [edi], 0
                    pop ebx
                    pop edi
                    pop esi
                    pop ebp
                    ret

.out_char:          mov [edi], al
                    inc edi
                    jmp .continue

.set_plus:          or eax, FLAG_PLUS_STATE
                    jmp .continue

.set_space:         or eax, FLAG_SPACE_STATE
                    jmp .continue

.set_minus:         or eax, FLAG_MINUS_STATE
                    jmp .continue

.set_zero:          or eax, FLAG_ZERO_STATE
                    jmp .continue

.maybe_set_long:    lea edx, [esi + 1]
                    cmp byte [edx], 'l'
                    jne .out_char
                    or eax, SIZE_LONG_STATE
                    inc esi
                    jmp .continue

.maybe_read_width:  cmp al, '9'
                    jg .maybe_continue
                    jmp hw_atoi

;; output malformed control chars as-is
.out_malformed:     mov byte [edi], '%'
                    inc edi
                    mov [edi], al
                    inc edi
                    xor eax, eax
                    xor ebx, ebx
                    jmp .continue

.out_uint:          or eax, UNSIGNED_STATE
.out_int:           test eax, SIZE_LONG_STATE
                    jz out32
                    jmp out64


section .rodata

;; possible remainders occuring during 64-bit division to 10
rem_table           db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3
