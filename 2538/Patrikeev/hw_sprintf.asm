global hw_sprintf

extern printf

%define set_flag(x)  or ebx, x
%define test_flag(x) test ebx, x
%assign plus_flag    1 << 1 ;; '+' specified
%assign minus_flag   1 << 2 ;; '-' specified
%assign zero_flag    1 << 3 ;; '0' specified
%assign space_flag   1 << 4 ;; ' ' specified
%assign long_flag    1 << 5 ;; 'll' specified
%assign unsign_flag  1 << 6 ;; 'u' specified
%assign neg_flag     1 << 7 ;; current printing number is negative 

section .bss
next_ptr:   resq     1      ;;next_ptr is a pointer to next number to be printed

section .text

;;the main function of the party
;;void hw_sprintf(char *out, char const *format, ...);
hw_sprintf:
    push    ebp         ;;save caller's stack frame
    mov     ebp, esp    ;;establish new stack frame

    push    ebx         ;;save callee-saved registers
    push    edi
    push    esi
    
    mov     edi, [ebp + 8]       ;;1-st param (*out)
    mov     esi, [ebp + 12]      ;;2-d parameter (*format)
    lea     next_ptr, [ebp + 16] ;;point to 1-st number

;;allocate new "variable" that points to next number to be printed   
;;so [ebp-.ptr] contains address of next argument (int or long long whatever)
;;    sub     esp, 4      ;;get room for ptr
;;    mov     eax, [ebp + 16]         
;;    mov     [ebp-next_], eax ;;load address of the first number (3-d parameter of hw_sprintf)
        
    xor     eax, eax        ;;clear room for chars
.read_until_eol:
    xor     ecx, ecx        ;;ecx holds chars length (and number of pushed elements)

    mov     byte al, [esi]  ;;load next char
    inc     esi             ;;move (*format) pointer
    push    eax             ;;push char to be printed in future if error occurs
    inc     ecx             ;;one more char...
    cmp     byte al, 0      ;;if EOL, then print '\0' to (*out) and exit
    je      .print_pushed_chars
    cmp     byte al, '%'    ;;check if start of format string
    jne     .print_pushed_chars ;;if not, then just print this char

;;check if next char is also '%': if yes, then just print it correctly
    mov     byte al, [esi]  ;;peek next char if it is '%' too
    inc     esi             ;;move (*format) pointer
    cmp     byte al, '%'    
    je      .print_pushed_chars     ;;print only one '%' and go to next char if any
    dec     esi             ;;else unread peeked char
    
;;this label reads format string and sets flags:
    xor     ebx, ebx        ;;ebx holds encountered flags 
    xor     edx, edx        ;;edx holds format's width
.read_format_chars:
    mov     byte al, [esi]  ;;load next char 
    inc     esi             ;;move (*format) pointer
    push    eax             ;;push char to be printed in future
    inc     ecx             ;;one more char to be printed
    cmp     byte al, 0      
    je      .print_pushed_chars ;;if EOL, then print all already pushed chars and exit

;;check flags and set those one which have been encountered:
;;and move (*format) pointer properly
    cmp     byte al, '+'
    je      set_plus_flag    ;;set plus_flag and jump to .plus_flag_checked
.plus_flag_checked:

    cmp     byte al, '-'
    je      set_minus_flag   ;;set minus_flag and jump to .minus_flag_checked
.minus_flag_checked:

    cmp     byte al, '0'
    je      set_zero_flag    ;;set zero_flag and jump to .zero_flag_checked
.zero_flag_checked:

    cmp     byte al, ' '
    je      set_space_flag   ;;set space_flag and jump to .space_flag_checked
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

    mov     byte al, [esi]  ;;load next char
    inc     esi             ;;move (*format) pointer to next char
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
    je      set_unsigned_flag   ;;set unsign_flag and jump to .unsigned_flag_checked

    ;;'%%' has been checked earlier
    ;;we have not encountered any of available types => error => print chars
    jmp     .print_pushed_chars

.type_checked:
.unsigned_flag_checked:
;;all specifiers are OK, flags and "width" are set => print next number
    jmp     print_next_number
     
;;this label pops chars from the stack(in reverse order)
;;and writes them to room, starting at [edi] (in forward order)
;;and then moves [edi] by the number of printed chars
.print_pushed_chars:
    mov     ebx, ecx                  ;;save number of chars to be printed
    xor     edx, edx                  ;;edx == 1 if we should exit after this loop, else we should go to next char
.loop_print_chars:
    cmp     ecx, 0                    ;;check if there are any chars to be printed
    je      .end_print_pushed_chars   ;;no chars to be printed
    pop     eax                       ;;get next char to be printed(reverse order)
    mov     byte [edi + ecx - 1], al  ;;write char from the end of room(to get forward order)
    dec     ecx                       ;;one less char 
    cmp     byte al, 0                ;;if current char == '\0', then we should exit after printing all chars
    jne     .loop_print_chars
    mov     edx, 1                    ;;set flag about exit
    jmp     .loop_print_chars         ;;and continue to write the rest of bytes 

.end_print_pushed_chars:
    add     edi, ebx                  ;;move (*out) by number of chars which are printed 
    cmp     edx, 0                    ;;if we should continue, then do continue, else end of format string
    je      .read_until_eol

.end_read_until_eol:
;;we have proceed the whole format string
    
    pop     esi         ;;restore callee-saved registers
    pop     edi
    pop     ebx

    mov     esp, ebp    ;;restore stack
    pop     ebp         ;;restore caller's stack frame
    ret

;;these labels are convenient way to set flag if it has been encountered
;;and move pointer to next char properly
set_plus_flag:
    set_flag(plus_flag)
    mov     byte al, [esi] ;;load next after '+' char
    inc     esi            ;;move (*format)
    push    eax            ;;push char to be printed in future
    inc     ecx            ;;one more char...
    jmp hw_sprintf.plus_flag_checked
    
set_minus_flag:
    set_flag(minus_flag)
    mov     byte al, [esi] ;;load next after '-' char
    inc     esi            ;;move (*format)
    push    eax            ;;push char to be printed in future
    inc     ecx            ;;one more char...
    jmp hw_sprintf.minus_flag_checked

set_zero_flag:
    set_flag(zero_flag)
    mov     byte al, [esi] ;;load next after '0' char
    inc     esi            ;;move (*format)
    push    eax            ;;push char to be printed in future
    inc     ecx            ;;one more char...
    jmp hw_sprintf.zero_flag_checked

set_space_flag:
    set_flag(space_flag)
    mov     byte al, [esi] ;;load next after ' ' char
    inc     esi            ;;move (*format)
    push    eax            ;;push char to be printed in future
    inc     ecx            ;;one more char...
    jmp hw_sprintf.space_flag_checked

set_unsigned_flag:
    set_flag(unsign_flag)
    jmp hw_sprintf.unsigned_flag_checked

set_long_flag:
    set_flag(long_flag)
    jmp hw_sprintf.long_flag_checked

;;this label determines a kind of number, converts int -> int64
;;prints number, moves (*out) pointer properly and goes to a next char
;;it doesn't require any parameters, as far as they all are in appropriate places
;;-------------------------------------------------------------------------------
;;ebx - holds flags
;;edx - holds minimal "width"
;;next_ptr - address of next value 
print_next_number:
    ;;here it is all the work
    jmp read_until_eol


print_unsigned_long:             
    push    esi         ;;save ESI (*format) to make it usable
    push    ebx         ;;save EBX (flags) to make it usable
    
    mov     edx, [next_ptr + 12] ;;most-significant bits: let it name A
    mov     eax, [next_ptr + 8]  ;;less-significant bits: let it name B
                                 ;;so EDX:EAX == A:B
    xor     ecx, ecx             ;;ECX is length of number in digits
    mov     ebx, 10              ;;divisor
.divide_until_zero:
    mov     esi, eax  ;; save value of EAX==B in ESI
                      ;; EDX:EAX == A:B
    xchg    edx, eax  ;; EDX:EAX == B:A
    xor     edx, edx  ;; EDX:EAX == 0:A
    div     ebx       ;; EDX:EAX == A % 10 : A / 10
    xchg    esi, eax  ;; EDX:EAX == A % 10 : B  and ESI == A / 10
    div     ebx       ;; EDX:EAX == (((A % 10) << 32) + B) % 10 : (((A % 10) << 32) + B) / 10
                      ;; EDX:EAX == (....it's a new digit.....) : (..........remainder......)
    
    ;; EDX holds new digit
    mov     byte [edi], dl
    inc     edi
    inc     ecx

    ;push    edx       ;;push current digit on stack(in future we will get forward representation)
    ;inc     ecx       ;;increment number's length

    mov     edx, esi  ;; EDX:EAX == A / 10 : (((A % 10) << 32) + B) / 10
                      ;; for now (EDX * 2^32 + EAX) is exactly ((A * 2^32 + B) / 10)
                      ;; that is EDX:EAX == new_A:new_B == newEDX:newEAX

    or      esi, eax           ;;check if (EDX:EAX) == 0
    cmp     esi, 0
    jnz     .divide_until_zero ;;if yes, then stop division 

.after_division:
    pop     ebx         ;;restore flags
    test_flag(plus_flag)
    jz      .plus_flag_proceed  ;;jump if plus flag is not set 
    mov     byte [edi], '+'
    
.plus_flag_proceed:


    pop     esi     ;;restore ESI

    ret
