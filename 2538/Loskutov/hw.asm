;;;; Most functions do not comply the cdecl calling convention
;;;; Parameters are stored (and the result is returned) in the registers
;;;; for better performance (close to borland fastcall)
;;;; Actually hw_sprintf is the only cdecl procedure
%define FLAG_SIGN      1
%define FLAG_SPACE     2
%define FLAG_MINUS     4
%define FLAG_ZERO      8
%define FLAG_LONG     16
%define FLAG_UNSIGNED 32
%define FLAG_NEGATIVE 64 ; not actually a format string flag, but used to handle negative numbers

%macro NEXT_CHAR 0
    inc esi
    mov dl, [esi] ; LODSB is nice, but EAX is used to store the result of the multiplication
%endmacro

;;; copies the null-terminated string on the stack to [edi], incrementing both pointers
%macro STRCPY 0
    cld
    .inner_strcpy
        mov  al, [esp]
        stosb                ;; I wish I could use MOVSB here,
        inc  esp             ;; but I need to remember the copied byte
        test al, al          ;; to know if it is the terminating NUL
        jnz  .inner_strcpy
    dec     edi              ; edi now points at the terminating NUL
%endmacro

global hw_sprintf

extern puts

section .text
;;; cdecl procedure
;;; a simplified analog of the sprintf function
;;; void hw_sprintf(char *out, char const *format, ...);
hw_sprintf:
    push    edi
    push    esi
    push    ebx
    push    ebp
    mov     edi, [esp + 20]
    mov     esi, [esp + 24]
    lea     ebp, [esp + 28]  ; the current argument
    ; dh — flags
    ; dl — current char
    ; ebx — pointer to the beginning of the current control seq (NULL if we aren't in a control seq)
    ; eax — width
    xor     ebx, ebx         ; not inside a conrol sequence until got '%'
    xor     eax, eax         ; consider width = 0 until it’s set
    xor     dh, dh           ; no flags on start


    .mainloop
        mov  dl, [esi]
        test dl, dl
        jz   .regular

        ; PARSE THE FLAGS
        .test_control:
        cmp  dl, '%'
        jne  .regular
        test ebx, ebx
        jnz  .incorrect
        xor  dh, dh
        mov  ebx, esi
        NEXT_CHAR

        .control_loop:
            .test_plus:
            cmp  dl, '+'
            jne  .test_space
            or   dh, FLAG_SIGN
            jmp  .control_end

            .test_space:
            cmp  dl, ' '
            jne  .test_minus
            or   dh, FLAG_SPACE
            jmp  .control_end

            .test_minus:
            cmp  dl, '-'
            jne  .test_zero
            or   dh, FLAG_MINUS
            jmp  .control_end

            .test_zero:
            cmp  dl, '0'
            jne  .parse_width
            or   dh, FLAG_ZERO
            jmp  .control_end

            .control_end:
            NEXT_CHAR
            test dl, dl
            jnz  .control_loop

        ; PARSE THE WIDTH
        .parse_width:
        xor  eax, eax       ; the width is 0 initially
        dec  esp
        mov  [esp], dh      ; edx will be lost during the multiplication
        mov  ecx, 10
        .width_loop:
        cmp  dl, '0'
        jl   .width_end
        cmp  dl, '9'
        jg   .width_end
        push edx
        mul  ecx            ; ecx is supposed to be 10
        pop  edx
        sub  dl, '0'
        xor  ecx, ecx       ;; one does not simply add dl to eax,
        mov  cl, dl         ;; so let’s first copy it into ecx
        add  eax, ecx
        mov  ecx, 10        ; restore ecx then
        NEXT_CHAR
        jmp  .width_loop
        .width_end
        mov  dh, [esp]      ; restore the flags
        inc  esp

        ; PARSE THE SIZE
        .parse_sz:
        cmp  dl, 'l'
        jne  .parse_t
        NEXT_CHAR
        cmp  dl, 'l'
        jne  .incorrect
        or   dh, FLAG_LONG
        NEXT_CHAR


        ; PARSE THE TYPE
        .parse_t:
        cmp  dl, '%'
        jne  .notperc
        xor  ebx, ebx         ; type is always the last symbol in the control sequence
        jmp  .regular
        .notperc
        cmp  dl, 'd'
        je   .int
        cmp  dl, 'i'
        je   .int
        cmp  dl, 'u'
        jne  .incorrect
        or   dh, FLAG_UNSIGNED

        .int:
        test dh, FLAG_LONG
        jnz  .long
        push eax
        push ecx
        push edx
        mov  ecx, eax
        mov  eax, [ebp]       ; take the next argument
        add  ebp, 4
        dec  esp
        mov  [esp], dh
        push ecx
        call int_to_string
        pop  edx
        pop  ecx
        pop  eax
        xor  ebx, ebx         ; type is always the last symbol in the control sequence
        jmp  .end

        .long
        push eax
        push ecx
        push edx
        mov  ebx, eax
        mov  ch, dh
        mov  eax, [ebp]       ; take the next argument
        mov  edx, [ebp + 4]
        add  ebp, 8
        dec  esp
        mov  [esp], ch        ; push the flags to the stack
        push ebx
        call long_to_string
        pop  edx
        pop  ecx
        pop  eax
        xor  ebx, ebx         ; type is always the last symbol in the control sequence
        jmp  .end


        .incorrect:
        mov  esi, ebx
        mov  dl, [esi]
        xor  ebx, ebx

        .regular
        mov  [edi], dl
        inc  edi

        .end:
        inc  esi
        test  dl, dl
        jnz  .mainloop

    pop     ebp
    pop     ebx
    pop     esi
    pop     edi
    ret

; procedure printing an unsigned long into a buffer.
; Parameters:
; edx:eax — the number
; edi — pointer to the buffer
; [ebp + 12] — width
; [ebp + 16] — flags
; return value: none
; discards eax, ecx, edx
ulong_to_string:
    push    ebx
    push    ebp
    mov     ebp, esp
    ; copy the string representation of the number to the stack
    push    byte 0
    mov     ecx, 10
    .iterate
        push eax
        mov  eax, edx
        xor  edx, edx
        div  ecx             ; divide the high-order half first
        mov  ebx, eax
        pop  eax             ; then divide the low-order half
        div  ecx
        xchg ebx, edx        ; combine the quotents
        add  bl, '0'
        dec  esp
        mov  [esp], bl
        test eax, eax
        jnz  .iterate        ; iterate until eax is zero

    test    byte [ebp + 16], FLAG_SIGN
    jz      .add_space
    test    byte [ebp + 16], FLAG_ZERO
    jnz     .fill_w ; if we need to fill the result with zeros, let’s do it before adding the sign
    dec     esp
    test    byte [ebp + 16], FLAG_NEGATIVE
    jz      .add_plus
    mov     [esp], byte '-'
    jmp     .fill_w
    .add_plus
    mov     [esp], byte '+'
    jmp     .fill_w

    .add_space
    test    byte [ebp + 16], FLAG_SPACE
    jz      .fill_w
    dec     esp
    mov     [esp], byte ' '

    .fill_w
    lea     ecx, [esp + 4]
    add     ecx, [ebp + 12]
    sub     ecx, ebp
    test    byte [ebp + 16], FLAG_SIGN
    jz      .no_sign_needed
    test    byte [ebp + 16], FLAG_ZERO
    jz      .no_sign_needed ; if both flags are present, the sign needs to be inserted before the zeros
    dec     ecx
    .no_sign_needed
    test    ecx, ecx
    jns     .test_zero
    xor     ecx, ecx         ; width should not be negative!
    .test_zero
    test    byte [ebp + 16], FLAG_MINUS
    jnz     .space
    test    byte [ebp + 16], FLAG_ZERO
    jz      .space
    mov     dl, '0'
    jmp     .pre_fill_loop
    .space                   ; fill with zeros by default
    mov     dl, ' '

    .pre_fill_loop
    test    byte [ebp + 16], FLAG_MINUS
    jnz     .strcpy
    .fill_loop
        test  ecx, ecx
        jz   .strcpy
        dec  esp
        mov  [esp], dl
        loop .fill_loop

    ; insert the sign if needed
    test    byte [ebp + 16], FLAG_SIGN
    jz      .strcpy
    test    byte [ebp + 16], FLAG_ZERO
    jz      .strcpy
    dec     esp
    test    byte [ebp + 16], FLAG_NEGATIVE
    jnz     .negative
    mov     [esp], byte '+'
    jmp     .strcpy
    .negative
    mov     [esp], byte '-'

    .strcpy
    STRCPY

    test    byte [ebp + 16], FLAG_MINUS
    jz      .end
    mov     al, dl
    rep     stosb           ; fill the rest if minus flag specified

    .end:
    mov     esp, ebp
    pop     ebp
    pop     ebx
    ret     5

; function printing a long into a buffer.
; Parameters:
; edx:eax — the number
; edi — pointer to the buffer
; [esp + 4] — width
; [esp + 8] — flags
; return value: none
; discards eax, ecx, edx
long_to_string:
    test    byte [esp + 8], FLAG_UNSIGNED
    jnz     ulong_to_string
    test    edx, edx
    jns     ulong_to_string
    not     edx
    test    eax, eax         ; handle overflow when the low-order half is zero
    jnz     .notzero
    inc     edx
    .notzero
    neg     eax
    or      byte [esp + 8], FLAG_NEGATIVE | FLAG_SIGN ; don’t forget about the “−” sign!
    jmp     ulong_to_string

; procedure printing an unsigned int into a buffer.
; Parameters:
; eax — the number
; edi — pointer to the buffer
; [ebp + 8] — width
; byte [ebp + 12] — flags
; return value: none
; edi on return points to the terminating NUL
; discards eax, ecx, edx
uint_to_string:
    push    ebp
    mov     ebp, esp

    ; copy the string representation of the number to the stack
    push    byte 0
    mov     ecx, 10
    .iterate
        xor  edx, edx
        div  ecx
        add  dl, '0'
        dec  esp
        mov  [esp], dl
        test eax, eax
        jnz  .iterate

    test    byte [ebp + 12], FLAG_SIGN
    jz      .add_space
    test    byte [ebp + 12], FLAG_ZERO
    jnz     .fill_w ; if we need to fill the results with zeros, let’s do it before adding the sign
    dec     esp
    test    byte [ebp + 12], FLAG_NEGATIVE
    jz      .add_plus
    mov     [esp], byte '-'
    jmp     .fill_w
    .add_plus
    mov     [esp], byte '+'
    jmp     .fill_w

    .add_space
    test    byte [ebp + 12], FLAG_SPACE
    jz      .fill_w
    dec     esp
    mov     [esp], byte ' '

    .fill_w
    lea     ecx, [esp + 4]
    add     ecx, [ebp + 8]
    sub     ecx, ebp
    test    byte [ebp + 12], FLAG_SIGN
    jz      .no_sign_needed
    test    byte [ebp + 12], FLAG_ZERO
    jz      .no_sign_needed ; if both flags are present, the sign needs to be inserted before the zeros
    dec     ecx
    .no_sign_needed
    test    ecx, ecx
    jns     .test_zero
    xor     ecx, ecx         ; width should not be negative!
    .test_zero
    test    byte [ebp + 12], FLAG_MINUS
    jnz     .space
    test    byte [ebp + 12], FLAG_ZERO
    jz      .space
    mov     dl, '0'
    jmp     .pre_fill_loop
    .space                   ; fill with zeros by default
    mov     dl, ' '

    .pre_fill_loop
    test    byte [ebp + 12], FLAG_MINUS
    jnz     .strcpy
    .fill_loop
        test ecx, ecx
        jz   .strcpy
        dec  esp
        mov  [esp], dl
        loop .fill_loop

    ; insert the sign if needed
    test    byte [ebp + 12], FLAG_SIGN
    jz      .strcpy
    test    byte [ebp + 12], FLAG_ZERO
    jz      .strcpy
    dec     esp
    test    byte [ebp + 12], FLAG_NEGATIVE
    jnz     .negative
    mov     [esp], byte '+'
    jmp     .strcpy
    .negative
    mov     [esp], byte '-'

    .strcpy
    STRCPY

    test    byte [ebp + 12], FLAG_MINUS
    jz      .end
    mov     al, dl
    rep     stosb           ; fill the rest if minus flag specified

    .end:
    mov     esp, ebp
    pop     ebp
    ret     5


; procedure printing an int into a buffer.
; Parameters:
; eax — the number
; edi — pointer to the buffer
; [esp + 4] — width
; [esp + 8] — flags
; discards eax, ecx, edx
int_to_string:
    test    byte [esp + 8], FLAG_UNSIGNED
    jnz     uint_to_string
    test    eax, eax
    jns     uint_to_string
    neg     eax
    or      byte [esp + 8], FLAG_NEGATIVE | FLAG_SIGN ; don’t forget about the “−” sign!
    jmp     uint_to_string
