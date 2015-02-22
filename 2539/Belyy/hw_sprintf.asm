global hw_sprintf

section .text

CONTROL_FLAG_STATE  equ     1 << 8
FLAG_PLUS_STATE     equ     1 << 9
FLAG_SPACE_STATE    equ     1 << 10
FLAG_MINUS_STATE    equ     1 << 11
FLAG_ZERO_STATE     equ     1 << 12
SIZE_LONG_STATE     equ     1 << 13


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
out_int32:          push eax
                    push ebx
                    xor ebx, ebx
                    mov ecx, [ebp]
.calculate_len:     mov eax, 1717986919
                    imul ecx
                    mov ecx, edx
                    shr ecx, 31
                    sar edx, 2
                    lea ecx, [ecx + edx]    ; ecx = ecx / 10
                    inc ebx
                    test ecx, ecx
                    jnz .calculate_len
                    sub [esp], ebx
                    cmp dword [ebp], 0
                    jl .dec_width
                    test dword [esp + 4], FLAG_PLUS_STATE | FLAG_SPACE_STATE
                    jnz .dec_width
.after_dec:         test dword [esp + 4], FLAG_MINUS_STATE | FLAG_ZERO_STATE
                    jz .out_left_spaces
.out_sign:          cmp dword [ebp], 0
                    jl .out_minus
                    test dword [esp +4], FLAG_PLUS_STATE
                    jnz .out_plus
                    test dword [esp +4], FLAG_SPACE_STATE
                    jnz .out_space
.after_sign:        test dword [esp + 4], FLAG_MINUS_STATE
                    jz .out_zeros
.out_number:        lea edi, [edi + ebx]
                    mov ecx, [ebp]
.out_number_loop:   dec edi
                    mov byte [edi], '0'
                    mov eax, 1717986919
                    imul ecx
                    mov ecx, edx
                    shr ecx, 31
                    sar edx, 2
                    lea ecx, [ecx + edx]
                    imul ecx, 10
                    mov eax, [ebp]
                    sub eax, ecx            ; eax = ecx % 10
                    add [edi], al
                    mov eax, 1717986919
                    imul ecx
                    mov ecx, edx
                    shr ecx, 31
                    sar edx, 2
                    lea ecx, [ecx + edx]    ; ecx = ecx / 10
                    mov [ebp], ecx
                    test ecx, ecx
                    jnz .out_number_loop
                    lea edi, [edi + ebx]
                    test dword [esp + 4], FLAG_MINUS_STATE
                    jnz .out_right_spaces
.finally:           add esp, 8
                    add ebp, 4
                    xor eax, eax
                    xor ebx, ebx
                    jmp hw_sprintf.continue

.dec_width:         dec dword [esp]
                    jmp .after_dec

.out_left_spaces:   mov ecx, [esp]
.left_spaces_loop:  cmp ecx, 0
                    jle .left_finally
                    mov byte [edi], ' '
                    inc edi
                    dec ecx
                    jmp .left_spaces_loop
.left_finally:      mov dword [esp], 0
                    jmp .out_sign

.out_zeros:         mov ecx, [esp]
.zeros_loop:        cmp ecx, 0
                    jle .out_number
                    mov byte [edi], '0'
                    inc edi
                    dec ecx
                    jmp .zeros_loop

.out_right_spaces:  mov ecx, [esp]
.right_spaces_loop: cmp ecx, 0
                    jle .finally
                    mov byte [edi], ' '
                    inc edi
                    dec ecx
                    jmp .right_spaces_loop

.out_minus:         mov byte [edi], '-'
                    inc edi
                    jmp .after_sign

.out_plus:          mov byte [edi], '+'
                    inc edi
                    jmp .after_sign

.out_space:         mov byte [edi], ' '
                    inc edi
                    jmp .after_sign


; (* note to self : I can safely use EAX, ECX and EDX
; if I want to use EBX, ESI, EDI or EBP, I should preserve them *)

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

.out_int:           test eax, SIZE_LONG_STATE
                    jz out_int32
; not implemented yet
.out_uint:          jmp .continue
