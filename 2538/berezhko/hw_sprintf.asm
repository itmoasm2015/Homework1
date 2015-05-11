global hw_sprintf

section .text

; FLAGS
PERCENT_FLAG        equ     1 << 1  ; is format consequence
SIGN_FLAG           equ     1 << 2  ; always print '+' or '-' before number
SPACE_FLAG          equ     1 << 3  ; print space before number if sign not printed
ALIGN_FLAG          equ     1 << 4  ; align to left (to right otherwise)
FILL_ZERO_FLAG      equ     1 << 5  ; fill empty space by zeros (by spaces otherwise),
                                    ; has lower priority than ALIGN_FLAG
; SIZE
LL_SIZE             equ     1 << 6  ; 8 bytes

; TYPE
P_TYPE              equ     1 << 7  ; %
I_TYPE              equ     1 << 8  ; i
D_TYPE              equ     1 << 9  ; d
U_TYPE              equ     1 << 10 ; u

; EXTRA
IS_NEG              equ     1 << 11 ; flag for negative numbers


;; Convert string to number
;;
;; Input:
;;      edi - string
;; Output:
;;      eax - number from string
;; Data changing:
;;      This function changes edi and at the end of
;;      converting edi will be at the char after number
;;      Example: dd111ss -> dd111ss
;;                 ^             ^
;;                rdi           rdi
%macro str2number 0
    push ebx
    xor esi, esi        ; esi = result

    %%loop:
        cmp byte[edi], '0'
        jl %%overit          ; if < '0' break
        cmp byte[edi], '9'
        jg %%overit          ; if > '9' break

        xor eax, eax        ;
        mov al, byte[edi]   ; eax - current digit
        sub al, '0'         ;

        push eax
        mov eax, esi        ; eax = current result
        mov ebx, 10         ;
        mul ebx             ; new_res = cur_res * 10
        mov esi, eax        ; esi = cur_res
        pop eax

        add esi, eax        ; new_res += current_digit

        inc edi             ; s++
        jmp %%loop
    %%overit:

    mov eax, esi        ; eax = result
    pop ebx
%endmacro

;; Writes char from [edi] to [esi]
;;
;; Data changing:
;;      esi will be point to the next cell of memory
%macro write_char 0
    push eax
    mov al, byte[edi]   ; al - char for write
    mov [esi], al       ; wtite to esi
    inc esi             ; esi++
    pop eax
%endmacro

;; Write char to [esi..esi+n-1]
;;
;; Input:
;;      %1 - char
;;      %2 - n
%macro write_char_n 2
    push edx
    mov dl, %1          ; dl = char
    mov eax, %2         ; eax = counter
    %%loop:
        cmp eax, 0      ;
        jle %%overit    ; check counter
        mov [esi], dl   ; write char
        inc esi
        dec eax
        jmp %%loop
    %%overit:
    pop edx
%endmacro

;; Write consequence to esi
;;
;; Input:
;;      edx - flags
;;      ebx - width
%macro write_seq_macro 0
    push ebx
    push edi
    mov ecx, edx            ; ecx - flags
    mov edi, ebx            ; edi = width

    mov edx, [ebp+4]    ;
    inc edx             ; arg_count++
    mov [ebp+4], edx    ;

    mov eax, [ebp+(edx+5)*4]
    test ecx, LL_SIZE
    jnz .implement_long
    test ecx, U_TYPE
	jnz .extract_digits_int
    test eax, eax
    jge .extract_digits_int

    neg eax                 ; eax = abs(arg)
    or ecx, IS_NEG

    .extract_digits_int:
    push 0                  ; by this hack we will check that we print all digits
    .loop_div_int
        xor edx, edx
        push ecx
        mov ecx, 10
        div ecx             ; edx=eax%10, eax=eax/10
        add edx, '0'
        pop  ecx
        push edx
        dec edi             ; width--
        cmp eax, 0
        jne .loop_div_int

    jmp .check_width

    .implement_long:
    mov edx, [ebp+4]    ;
    inc edx             ; arg_count++
    mov [ebp+4], edx    ;

    mov edx, [ebp+(edx+5)*4]

    test ecx, U_TYPE
	jnz .extract_digits_long
    test edx, edx
    jge .extract_digits_long

    not eax			        ;
	not edx                 ;
	add eax, 1              ;
	adc edx, 0              ; edx:eax = abs(arg)

	or ecx, IS_NEG

    .extract_digits_long:
    push 0                  ; by this hack we will check that we print all digits
    .loop_div_long
        push ecx
        mov ecx, 10         ; ecx = 10
        mov ebx, eax        ; save low part of arg
        xchg eax, edx       ; edx:eax -> eax:edx
        xor edx, edx        ; eax:edx -> 0:edx
        div ecx             ; (edx%10):(edx/10)
        xchg eax, ebx       ; (edx%10):eax=((edx%10)*(2**64))+eax
        div ecx             ; ((((edx%10)*(2**64))+eax)%10):((((edx%10)*(2**64))+eax)/10)
        pop ecx
        add edx, '0'
        push edx            ; write all character on the stack
        mov edx, ebx        ; eax:((((edx%10)*(2**64))+eax)/10)
        dec edi             ; width--
        or ebx, eax
        cmp ebx, 0
        jne .loop_div_long

    .check_width:

    test ecx, IS_NEG
    jnz .print_sign
    test ecx, SIGN_FLAG
    jnz .print_sign
    test ecx, SPACE_FLAG
    jnz .print_space

    jmp .print_width

    .print_sign:
    test ecx, IS_NEG
    jz .print_plus
    mov dl, '-'
    push edx
    dec edi                 ; width--
    jmp .print_width
        .print_plus:
        mov dl, '+'
        push edx
        dec edi             ; width--
        jmp .print_width

    .print_space:
    mov dl, ' '
    push edx
    dec edi                 ; width--

    .print_width:
    test ecx, ALIGN_FLAG
    jnz .print_digits

    test ecx, FILL_ZERO_FLAG
    jnz .align0

    write_char_n ' ', edi
    jmp .print_digits

    .align0:
    write_char_n '0', edi
    jmp .print_digits

    ; load digits (and sign) from stack:
    .print_digits:
        pop edx
        cmp edx, 0              ; check our hack
        je .over_print_digits
        mov [esi], dl
        inc esi
        jmp .print_digits
    .over_print_digits:

    test ecx, ALIGN_FLAG
    jz %%finish
    write_char_n ' ', edi
    %%finish:
    pop edi
    pop ebx
%endmacro

;; hw_sprintf(char *out, const char *format, ...)
;; format = %([0-+ ]*)([1-9][0-9]*)?(ll)?(u|i|d|%)
;;
;; This function is very similar to c++ sprintf()
;;
;; Differences: in this implementation you can write flag +
;; and sign of number will be written
hw_sprintf:
    push ebp
    mov ebp, esp
    push ebx
    push edi ; for format
    push esi ; for out
    mov esi, [ebp + 8] ; esi = out
    mov edi, [ebp + 12] ; edi = format

    sub ebp, 4              ; stack.top - current argument
    xor edx, edx
    mov [ebp], edx          ; cur_arg = 0
    sub ebp, 4              ; stack.top - '%' position

    .loop_format:
        xor edx, edx ; flags
        cmp byte[edi], '%'
        je .read_flags              ; if cur_char = '%', start read flags i.e.
        write_char                  ; otherwise, write cur_char to out(esi)
        jmp .continue
        ; read flags:
        .read_flags:
            mov [ebp], edi          ; stack.top = '%' position
            inc edi
            .sign:
            cmp byte[edi], '+'
            jne .space
            or edx, SIGN_FLAG
            jmp .cont
            .space:
            cmp byte[edi], ' '
            jne .align
            or edx, SPACE_FLAG
            jmp .cont
            .align:
            cmp byte[edi], '-'
            jne .fill_zero
            or edx, ALIGN_FLAG
            jmp .cont
            .fill_zero:
            cmp byte[edi], '0'
            jne .over_flag
            or edx, FILL_ZERO_FLAG
            .cont:
            inc edi
            jmp .sign
        .over_flag:

        .read_width:
        xor ebx, ebx
        cmp byte[edi], '0'  ;
        jl .read_size       ; check width field
        cmp byte[edi], '9'  ; can be
        jg .read_size       ;

        push esi
        push edx
        str2number      ; eax = width
        pop edx
        pop esi
        mov ebx, eax    ; ebx = width

        .read_size:

        cmp byte[edi], 'l'
        jne .read_type
        inc edi
        cmp byte[edi], 'l'
        jne .write_flags
        or edx, LL_SIZE
        inc edi
        .read_type:

        .u_type:
        cmp byte[edi], 'u'
        jne .i_type
        or edx, U_TYPE
        jmp .write_seq
        .i_type:
        cmp byte[edi], 'i'
        jne .d_type
        or edx, I_TYPE
        jmp .write_seq
        .d_type:
        cmp byte[edi], 'd'
        jne .p_type
        or edx, D_TYPE
        jmp .write_seq
        .p_type:
        cmp byte[edi], '%'
        jne .write_flags
        or edx, U_TYPE
        mov dl, '%'
        mov [esi], dl
        inc esi
        jmp .continue

        .write_flags:
        push eax
        push edx
        mov eax, [ebp] ; eax = %.position
        ; write all characters from %.position to edi
        .loop_flags:
            mov dl, byte[eax]
            mov [esi], dl
            inc esi
            inc eax
            cmp eax, edi
            jl .loop_flags
        pop edx
        pop eax

        sub edi, 1
        jmp .continue

        .write_seq:
        write_seq_macro
        .continue:
        inc edi
        cmp byte[edi], 0
        jne .loop_format

    .over_format:

    mov [esi], byte 0

    .finish:

    add ebp, 8 ; 4 for %.posiiton and 4 for arg count
    ; cdecl:
    pop esi
    pop edi
    pop ebx
    pop ebp
    ret
