global hw_sprintf

%define set_flag(x)  or ebx, x
%define test_flag(x) test ebx, x
%assign plus_flag    1 << 1
%assign minus_flag   1 << 2
%assign zero_flag    1 << 3
%assign space_flag   1 << 4
%assign long_flag    1 << 5
%assign unsign_flag  1 << 6

extern printf

section .data
FORMAT_STRING:      db      '%08x', 10, 0

section .text

;;void hw_sprintf(char *out, char const *format, ...);
hw_sprintf:
    push    ebp         ;;save caller's stack frame
    mov     ebp, esp    ;;establish new stack frame

    push    ebx
    push    edi
    push    esi

    mov     edi, [ebp + 8]  ;;1-st param (*out)
    mov     esi, [ebp + 12] ;;2-d parameter (*format)

    xor     eax, eax        ;;clear room for chars
.read_until_eol:
    xor     ecx, ecx        ;;ecx holds chars length

    mov     byte al, [esi]  ;;load next char
    push    eax             ;;push char to be printed in future if error occurs
    inc     ecx             ;;one more char...
    inc     esi             ;;move (*format) pointer
    cmp     byte al, 0
    je      .print_pushed_chars ;;if EOL, then print '\0' char to (*out) and exit

    mov     byte al, [esi]  ;;load next char
    push    eax             ;;push char to be printed in future if error occurs
    inc     ecx             ;;one more char...
    inc     esi             ;;move (*format) pointer
    cmp     byte al, '%'    ;;check if start of format string
    jne     .print_pushed_chars ;;if not, then just print this char

;;check if next char is also '%': if yes, then just print it correctly
    mov     byte al, [esi]  ;;load next char
    inc     esi             ;;move (*format) pointer
    cmp     byte al, '%'    
    je      .print_pushed_chars     ;;print only one '%'
    push    eax             ;;else push it as regular
    inc     ecx             ;;and increment number of chars to be printed
    
;;this label reads format string and sets flags:
    xor     ebx, ebx        ;;ebx holds encountered flags 
    xor     edx, edx        ;;edx holds format's width
.read_format_chars:
    mov     byte al, [esi]  ;;load next char 
    push    eax             ;;push char to be printed in future
    inc     ecx             ;;one more char to be printed
    inc     esi             ;;move (*format) pointer
    cmp     byte al, 0      
    je      .print_pushed_chars ;;if EOL, then print all already pushed chars and exit

    ;;check flags and set those one which have been encountered 
    cmp     byte al, '+'
    je      set_plus_flag
.plus_flag_checked:

    cmp     byte al, '-'
    je      set_minus_flag
.minus_flag_checked:

    cmp     byte al, '0'
    je      set_zero_flag
.zero_flag_checked:

    cmp     byte al, ' '
    je      set_space_flag
.space_flag_checked:

;;checks if digits sequence ("width") and parses it
.parse_width:
    xor     edx, edx        ;;edx holds parsed "width" 
.parse_width_loop:
    cmp     byte al, '0'
    jnge    .width_checked
    cmp     byte al, '9'
    jnle    .width_checked

    sub     eax, '0'        ;;EAX == current digit
    lea     edx, [edx+4*edx];;edx *= 5
    shl     edx, 1          ;;edx *= 2
    add     edx, eax        ;;edx += digit

    inc     esi             ;;move (*format) pointer to next char
    mov     byte al, [esi]  ;;load next char
    push    eax             ;;push char to be printed if error occurs
    inc     ecx             ;;one more char...
    cmp     al, 0           ;;if EOL(incorrect format sequence) then just print all pushed chars
    je      .print_pushed_chars

    jmp     .parse_width_loop 

.width_checked:

;;check if 'll' specifier
    cmp     byte al, 'l'
    jne     .long_flag_checked  

    ;;it may be 'll' specifier, so check if next char is 'l' too
    mov     byte al, [esi]  ;;load next char
    inc     esi             ;;move (*format) pointer
    push    eax             ;;push char to be printed in future
    inc     ecx             ;;one more char to be printed 
    cmp     byte al, 0
    je      .print_pushed_chars ;;if EOL (incorrect format sequence) => print chars

    cmp     byte al, 'l' 
    jne     .print_pushed_chars  ;;(incorrect format sequence) => print chars
    jmp     set_long_flag        ;;'ll' has been encountered
.long_flag_checked:

;;search for "type" specifier
    cmp     byte al, 'd'
    je      .type_checked

    cmp     byte al, 'i'
    je      .type_checked

    cmp     byte al, 'u'
    je      set_unsigned_flag
.unsigned_flag_checked:

    ;;'%%' has been checked earlier

    ;;specifiers are incorrect => print encountered chars
    jmp     .print_pushed_chars

.type_checked:
;;all specifiers are OK, do the main work:

     
;;this label pops chars from the stack(in reverse order)
;;and writes them to room, starting at [edi] (in forward order)
;;and then moves [edi] by the number of printed chars
.print_pushed_chars:
    mov     ebx, ecx                  ;;save number of chars to be printed
.loop_print_chars:
    cmp     ecx, 0                    ;;check if there are any chars to be printed
    je      .end_print_pushed_chars   ;;no chars to be printed
    pop     eax                       ;;get next char to be printed(reverse order)
    mov     byte [edi + ecx - 1], al  ;;write char from the end of room(to get forward order)
    dec     ecx                       ;;one less char 
    jmp     .loop_print_chars

.end_print_pushed_chars:
    add     edi, ebx                  ;;move (*out) by number of chars which are printed 
    
    jmp     .read_until_eol           ;;go to a next char

.end_read_until_eol:
;;we have proceed the whole format string
    
    pop     esi         ;;restore callee-saved registers
    pop     edi
    pop     ebx

    mov     esp, ebp    ;;restore stack
    pop     ebp         ;;restore caller's stack frame
    ret

set_plus_flag:
    set_flag(plus_flag)
    jmp hw_sprintf.plus_flag_checked
    
set_minus_flag:
    set_flag(minus_flag)
    jmp hw_sprintf.minus_flag_checked

set_zero_flag:
    set_flag(zero_flag)
    jmp hw_sprintf.zero_flag_checked

set_space_flag:
    set_flag(space_flag)
    jmp hw_sprintf.space_flag_checked

set_long_flag:
    set_flag(long_flag)
    jmp hw_sprintf.long_flag_checked

set_unsigned_flag:
    set_flag(unsign_flag)
    jmp hw_sprintf.unsigned_flag_checked


;; print_unsigned_long: push    ebp
print_unsigned_long:
    push    ebp
    mov     ebp, esp

    push    ebx
    push    edi
    push    esi

    mov     eax, [ebp + 8]  ;;less-significant bits: let it name A
    mov     edx, [ebp + 12] ;;most-significant bits: let it name B
    xor     ecx, ecx        ;;length of number
    mov     ebx, 10         ;;divisor
.divide_until_zero:
    mov     esi, eax  ;; save value of EAX==B in ESI
                      ;; EDX:EAX == A:B
    xchg    edx, eax  ;; EDX:EAX == B:A
    xor     edx, edx  ;; EDX:EAX == 0:A
    div     ebx       ;; EDX:EAX == A % 10 : A / 10
    xchg    esi, eax  ;; EDX:EAX == A % 10 : B  and ESI == A / 10
    div     ebx       ;; EDX:EAX == (((A % 10) << 32) + B) % 10 : (((A % 10) << 32) + B) / 10
                      ;;         == (....it's a new digit.....) : (..........remainder......)
                      ;; EDX holds new digit

    push    edx
    inc     ecx

    mov     edx, esi  ;; EDX:EAX == A / 10 : (((A % 10) << 32) + B) / 10
                      ;; for now (EDX * 2^32 + EAX) is exactly ((A * 2^32 + B) / 10)
                      ;; that is (new_A : new_B)

    or      esi, eax
    cmp     esi, 0
    jnz     .divide_until_zero  

.after_division:
    pop     edx
    push    eax
    push    ecx
    push    edx


    pop     edx
    pop     ecx
    pop     eax

    loop    .after_division

    pop     esi
    pop     edi
    pop     ebx

    mov     esp, ebp
    pop     ebp
    ret
