global hw_sprintf

section .text

PLUS_FLAG equ 1
SPACE_FLAG equ 2
MINUS_FLAG equ 4
ZERO_FLAG equ 8
LL_FLAG equ 16
SIGNED_FLAG equ 32
NEGATIVE_FLAG equ 64

hw_sprintf:
    push ebp
    mov ebp, esp
    push esi
    push eax
    push ecx

    mov eax, [ebp + 8] ; eax contains our out string
    mov ebx, [ebp + 12] ; ebx contains format string
    adc ebp, 16

.main_loop:
    cmp byte [ebx], 0 ; if last
    je .write_buffer ; then write our buffer
    
    cmp byte [ebx], '%'
    jne .write_symbol ; if our symbol is not '%' then output it
    mov edx, ebx ; our current buffer begins here
    inc ebx ; next symbol
    xor edi, edi ; our current flags
    jmp .set_flags

; writes our current buffer to answer and finishes the program
; if we don't have anything after buffer and goes to main_loop otherwise
.write_buffer:
    cmp byte [edx], 0 ; if our buffer ended and our format string
    je .end ; ended too, then we can finish our program
    cmp edx, ebx ; if our buffer ended
    je .main_loop ; then go back to loop for handling next symbols

    mov cl, byte [edx]
    mov byte [eax], cl ; move 1 symbol from buffer to answer
    inc eax
    inc edx
    jmp .write_buffer

; searches for all flags and sets them in edi
.set_flags:
    cmp byte [ebx], '+'
    je .set_plus_flag
    cmp byte [ebx], ' '
    je .set_space_flag
    cmp byte [ebx], '-'
    je .set_minus_flag
    cmp byte [ebx], '0'
    je .set_zero_flag
    jmp .get_width

.set_plus_flag:
    inc ebx ; next symbol
    or edi, PLUS_FLAG ; set bit in edi for plus flag
    jmp .set_flags
    
.set_space_flag:
    test edi, PLUS_FLAG ; check if bit for plus flag is set in edi
    inc ebx ; next symbol
    jz .set_flags ; if we have already set plus flag, then we ignore space flag
    or edi, SPACE_FLAG ; set bit in edi for space flag
    jmp .set_flags

.set_minus_flag:
    inc ebx ; next symbol
    or edi, MINUS_FLAG ; set bit in edi for minus flag
    jmp .set_flags

.set_zero_flag:
    test edi, MINUS_FLAG ; check if bit for minus flag is set in edi
    inc ebx ; next symbol
    jz .set_flags ; if we have already set minus flag, then we ignore zero flag
    or edi, ZERO_FLAG ; set bit in edi for zero flag
    jmp .set_flags

; gets width of our field
.get_width:
    xor esi, esi ; width of our field will be stored here

    .loop1:
        cmp byte [ebx], '9' ; if our symbol
        jg .have_width ; is not a digit
        cmp byte [ebx], '0' ; then we have
        jl .have_width ; already had width

        xor ecx, ecx
        mov cl, byte [ebx] ; find our digit
        inc ebx ; next symbol
        sub cl, '0' ; now cl is our digit, not it's code
        imul esi, 10 ; new number is old number multiplied by 10 and a new digit added to it
        add esi, ecx ; here we have current width in esi including last digit stored in cl
        jmp .loop1

    .have_width:
        jmp .get_ll_flag

; determines whether our number is long long and sets flag according to it
.get_ll_flag:
    cmp word [ebx], 'll' ; check if we have long long specifier
    jne .get_type ; if not go futher
    add ebx, 2 ; next symbol, 2 symbols in 'll', therefore we added 2
    or edi, LL_FLAG ; set bit in edi for long long flag
    jmp .get_type

; sets flag for signed number and then goes further to find our number
.set_signed_number:
    or edi, SIGNED_FLAG ; set bit in edi for signed number flag
    jmp .find_number

; determines type of our data
.get_type:
    cmp byte [ebx], '%' ; if our type is percent
    je .write_symbol ; then just output it and go futher
    cmp byte [ebx], 'i' ; if our type
    je .set_signed_number ; is signed number
    cmp byte [ebx], 'd' ; then set flags
    je .set_signed_number ; in edi according to it
    cmp byte [ebx], 'u' ; if our type is unsigned number
    je .find_number ; then go further to find our number
    inc ebx ; next symbol in order our buffer to write in answer last handled symbol
    jmp .write_buffer ; if we have unknown type, then just output our current buffer

; determines whether our number is long long or not and goes to another label according to it
.find_number:
    inc ebx ; next symbol after type symbol
    test edi, LL_FLAG ; see if our number is long long
    jz .get_int_negative_flag
    jmp .get_ll_negative_flag

; sets negative flag for number if it is signed and negative
.get_int_negative_flag:
    test edi, SIGNED_FLAG ; check if our sumber is signed
    jz .get_int ; go directly to label, where we get our number
    mov ecx, [ebp] ; ecx now contains our current number (argument)
    cmp ecx, 0 ; if our number >= 0
    jge .get_int ; then go directly to label, wehre we get our number
    or edi, NEGATIVE_FLAG ; set negative flag for number
    xor edx, edx ; previously pointer on '%' symbol (first in our buffer), but format string is good, therefore we don't need buffer anymore
    sub edx, ecx ; edx = -ecx
    mov [ebp], edx ; ebp points on positive integer now (if signed)
    jmp .get_int

; sets negative flag for long long number if it is signed and negative
.get_ll_negative_flag:
    test edi, SIGNED_FLAG ; check if our number is signed
    jz .get_ll ; go directly to label, where we get our number
    mov ecx, [ebp]
    mov edx, [ebp + 4] ; our number is (edx:ecx) now
    cmp edx, 0 ; if our number >= 0
    jge .get_ll ; then go directly to label, where we get our number
    or edi, NEGATIVE_FLAG ; set negative flag for number
    not ecx ; we get negate
    not edx ; number using
    add ecx, 1 ; two's complement
    adc edx, 0 ; representation of number
    mov [ebp], ecx
    mov [ebp + 4], edx ; now points on positive integer (if signed)
    jmp .get_ll

.get_int:
    push ebx ; remember value of next symbol to handle in format string
    call write_int ; call function, that writes our number
    adc ebp, 4 ; go to next argument
    pop ebx ; restore value of ebx after function
    mov edx, ebx ; no buffer right now
    jmp .main_loop ; go and handle other symbols in format string

.get_ll:
    push ebx ; remember value of next symbol to handle in format string
    call write_ll ; call function, that writes our number
    adc ebp, 8 ; go to next argument (long long - 8 bytes)
    pop ebx ; restore value of ebx after function
    mov edx, ebx ; no buffer right now
    jmp .main_loop ; go and handle other symbols in format string

; writes last symbol in format string to answer and then continues parsing our format string
.write_symbol:
    mov cl, byte [ebx]
    mov byte [eax], cl ; move our last symbol to answer
    inc eax ; next symbol in answer
    inc ebx ; next symbol in our format string
    mov edx, ebx ; our current buffer is now empty
    jmp .main_loop
    
.end:
    mov byte [eax], 0 ; finish our output string
    pop ecx
    pop eax
    pop esi
    pop ebp
    ret

write_int:
    xor ebx, ebx ; ebx is now length of our number

; checks some flags in order to determine,
; whether we need to write any symbol before number (minus, plus or space)
.write_before_int:
    test edi, NEGATIVE_FLAG ; check if our number is negative and signed
    jnz .write_minus_int ; then write minus before it
    test edi, PLUS_FLAG ; check if we have plus flag specified
    jnz .write_plus_int ; then write plus before number
    test edi, SPACE_FLAG ; check if we have space flag specified
    jnz .write_space_int ; then write space before number
    jmp .after_flags_int

; writes minus before number
.write_minus_int:
    mov byte [eax], '-' ; write '-' symbol to our output string
    inc eax ; next symbol
    inc ebx ; increase length of our number
    jmp .after_flags_int

; writes plus before number
.write_plus_int:
    mov byte [eax], '+' ; write '+' symbol to our output string
    inc eax ; next symbol
    inc ebx ; increase length of our number
    jmp .after_flags_int

; writes space before number
.write_space_int:
    mov byte [eax], ' ' ; write space to our output string
    inc eax ; next symbol
    inc ebx ; increase length of our number
    jmp .after_flags_int

; here we convert our number to string
.after_flags_int:
    push edi ; push information about flags on stack in order to save it
    push esi ; push field width on stack in order to save it
    push eax ; push pointer on next position of output string on stack
    mov esi, eax ; esi is now pointing on next position in our output string
    mov eax, [ebp] ; our current argument is in eax now

    ; converts reversed number to string
    .loop_int_to_string:
        mov edi, 10 ; our dividor is edi = 10
        xor edx, edx
        div edi ; eax is our quotient, edx is our remainder (last digit)
        add edx, 48 ; convert last digit to byte representation of it (48 is byte code of '0')
        mov [esi], edx ; write digit to our current answer
        inc ebx ; increase length of our number
        inc esi ; next symbol
        cmp eax, 0 ; if our quotient is 0
        jne .loop_int_to_string ; then we have converted our number to string

    pop edx ; begin of our output string is now in edx (previously in eax)
    push esi ; push position to write after number on stack
    dec esi ; pointer to last digit of our number

    ; reverses our string representation of number in order
    ; to receive our initial number
    .loop_reverse_int:
        mov al, byte [esi]
        mov cl, byte [edx]
        mov byte [esi], cl
        mov byte [edx], al ; after these 4 instructions we swapped s[i] and s[j] (where [j = n - i + 1] and n is length of our number)
        inc edx ; i++
        dec esi ; j--
        cmp edx, esi ; continue these operations
        jl .loop_reverse_int ; until we reach middle of our number

    pop esi ; restore position to write after number from stack
    pop edx ; restore field width from stack (previously in esi)
    pop edi ; restore information about flags from stack

    cmp ebx, edx ; if length of our number is greater or equals to required field width
    jge .finish_write_int ; then we finish our function and writing this number to output string
    test edi, MINUS_FLAG ; check, if we need to do left alignment
    jnz .align_left_int
    jmp .align_right_int

.align_right_int:
    mov ecx, edx
    sub ecx, ebx ; ecx now contains quantity of spaces or zeros we need to write before number
    push edx ; we push field width on stack in order to save it
    mov eax, esi ; position after number
    dec eax ; position, where number ends
    add eax, ecx ; eax now points on position, where number should end
    mov edx, esi ; position after number
    sub edx, ebx ; edx now points on position, where number starts
    push esi ; we push position after number on stack in order to save it
    dec esi

    .copy_int_to_right:
        push ecx ; push ecx on stack, because we need to use cl
        mov cl, byte [esi]
        mov byte [eax], cl ; move one digit ecx bytes to right
        pop ecx ; restore value of ecx
        dec eax ; previous byte
        dec esi ; previous digit
        cmp esi, edx ; if byte, from where we move our next digit, is less,
        jge .copy_int_to_right ; than start of our number, then we finish our shift

    inc esi ; position where we should start writing spaces or zeros
    inc eax ; first digit of our number

    test edi, ZERO_FLAG ; if we need to complete beginning of our number with zeros
    jnz .align_with_zeros_int ; then just do it
    jmp .align_with_spaces_int ; othwerwise complete it with spaces

.align_with_zeros_int:
    mov byte [esi], '0' ; write '0' symbol to output string
    inc esi ; next symbol
    cmp esi, eax ; if our current symbol isn't start of our number,
    jne .align_with_zeros_int ; we continue writing zeros
    pop esi ; restore value from stack
    pop edx ; restore value from stack
    adc esi, ecx ; now esi points on symbol next to our number
    jmp .finish_write_int

.align_with_spaces_int:
    mov byte [esi], ' ' ; write space to output string
    inc esi ; next symbol
    cmp esi, eax ; if our current symbol isn't start of our number,
    jne .align_with_spaces_int ; we continue writing spaces
    pop esi ; restore value from stack
    pop edx ; restore value from stack
    adc esi, ecx ; now esi points on symbol next to our number
    jmp .finish_write_int

.align_left_int:
    mov ecx, edx
    sub ecx, ebx ; ecx now contains quantity of spaces we need to append
    
    ; appends required number of spaces to number
    .loop_append_int:
        mov byte [esi], ' ' ; append 1 space symbol to our output string
        inc esi ; next symbol
        dec ecx ; one less space we need to append
        jnz .loop_append_int

    jmp .finish_write_int ; finish our function and writing our number to output string

.finish_write_int:
    mov eax, esi ; eax now points on next symbol to write in output string (as before function)
    ret ; finish our function

write_ll:
    xor ebx, ebx ; ebx is now length of our number

; checks some flags in order to determine,
; whether we need to write any symbol before number (minus, plus or space)
.write_before_ll:
    test edi, NEGATIVE_FLAG ; check if pur number is negative and signed
    jnz .write_minus_ll ; then write minus before it
    test edi, PLUS_FLAG ; check if we have plus flag specified
    jnz .write_plus_ll ; then write plus before number
    test edi, SPACE_FLAG ; check if we have space flag specified
    jnz .write_space_ll ; then write space before number
    jmp .after_flags_ll

; writes minus before number
.write_minus_ll:
    mov byte [eax], '-' ; write '-' symbol to our output string
    inc eax ; next symbol
    inc ebx ; increase length of our number
    jmp .after_flags_ll

; writes plus before number
.write_plus_ll:
    mov byte [eax], '+' ; write '+' symbol to our output string
    inc eax ; next symbol
    inc ebx ; increase length of our number
    jmp .after_flags_ll

; writes space before number
.write_space_ll:
    mov byte [eax], ' ' ; write space to our output string
    inc eax ; next symbol
    inc ebx ; increase length of our number
    jmp .after_flags_ll

; here we convert our number to string
.after_flags_ll:
    push edi ; push information about flags on stack in order to save it
    push esi ; push field width on stack in order to save it
    push eax ; push pointer on next position of output string on stack
    mov esi, eax ; esi is now pointing on next position in our output string
    mov eax, [ebp]
    mov edx, [ebp + 4] ; our current argument is in (edx:eax) now
    mov ecx, 10 ; ecx is our dividor from now

    .loop_ll_to_string:
        mov edi, eax ; edi now contains second part of our number
        xchg edx, eax ; let initial value of eax be init_eax, and init_edx for edx, so (edx:eax) = (init_eax:init_edx)
        xor edx, edx ; (edx:eax) = (0:init_edx)
        div ecx ; (edx:eax) = ((init_edx % 10):(init_edx / 10))
        xchg edi, eax ; (edx:eax) = ((init_edx % 10):init_eax)
        div ecx ; (edx:eax) = (((((init_edx % 10) << 32) + init_eax) % 10):(((init_edx % 10) << 32) + init_eax) / 10)
        add edx, 48 ; edx is our last digit, convert last digit to byte representation of it (48 is byte code of '0')
        mov [esi], edx ; write digit to our current answer
        inc ebx ; increase length of our number
        inc esi ; next symbol
        mov edx, edi ; edx = init_edx / 10
        or edi, eax ; if both parts are all zeros
        cmp edi, 0 ; then our number is 0
        jne .loop_ll_to_string ; and we have converted our number to string

    pop edx ; begin of our output string is now in edx (previously in eax)
    push esi ; push position to write after number on stack
    dec esi ; pointer to last digit of our number

    ; reverses our string representation of number in order
    ; to receive our initial number
    .loop_reverse_ll:
        mov al, byte [esi]
        mov cl, byte [edx]
        mov byte [esi], cl
        mov byte [edx], al ; after these 4 instructions we swapped s[i] and s[j] (where [j = n - i + 1] and n is length of our number)
        inc edx ; i++
        dec esi ; j--
        cmp edx, esi ; continue these operations
        jl .loop_reverse_ll ; until we reach middle of our number

    pop esi ; restore position to write after number from stack
    pop edx ; restore field width from stack (previously in esi)
    pop edi ; restore information about flags from stack

    cmp ebx, edx ; if length of our number is greater or equals to required field width
    jge .finish_write_ll ; then we finish our function and writing this number to output string
    test edi, MINUS_FLAG ; check, if we need to do left alignment
    jnz .align_left_ll
    jmp .align_right_ll

.align_right_ll:
    mov ecx, edx
    sub ecx, ebx ; ecx now contains quantity of spaces or zeros we need to write before number
    push edx ; we push field width on stack in order to save it
    mov eax, esi ; position after number
    dec eax ; position, where number ends
    add eax, ecx ; eax now points on position, where number should end
    mov edx, esi ; position after number
    sub edx, ebx ; edx now points on position, where number starts
    push esi ; we push position after number on stack in order to save it
    dec esi

    .copy_ll_to_right:
        push ecx ; push ecx on stack, because we need to use cl
        mov cl, byte [esi]
        mov byte [eax], cl ; move one digit ecx bytes to right
        pop ecx ; restore value of ecx
        dec eax ; previous byte
        dec esi ; previous digit
        cmp esi, edx ; if byte, from where we move our next digit, is less,
        jge .copy_ll_to_right ; than start of our number, then we finish our shift

    inc esi ; position where we should start writing spaces or zeros
    inc eax ; first digit of our number

    test edi, ZERO_FLAG ; if we need to complete beginning of our number with zeros
    jnz .align_with_zeros_ll ; then just do it
    jmp .align_with_spaces_ll ; othwerwise complete it with spaces

.align_with_zeros_ll:
    mov byte [esi], '0' ; write '0' symbol to output string
    inc esi ; next symbol
    cmp esi, eax ; if our current symbol isn't start of our number,
    jne .align_with_zeros_ll ; we continue writing zeros
    pop esi ; restore value from stack
    pop edx ; restore value from stack
    adc esi, ecx ; now esi points on symbol next to our number
    jmp .finish_write_ll

.align_with_spaces_ll:
    mov byte [esi], ' ' ; write space to output string
    inc esi ; next symbol
    cmp esi, eax ; if our current symbol isn't start of our number,
    jne .align_with_spaces_ll ; we continue writing spaces
    pop esi ; restore value from stack
    pop edx ; restore value from stack
    adc esi, ecx ; now esi points on symbol next to our number
    jmp .finish_write_ll

.align_left_ll:
    mov ecx, edx
    sub ecx, ebx ; ecx now contains quantity of spaces we need to append
    
    ; appends required number of spaces to number
    .loop_append_ll:
        mov byte [esi], ' ' ; append 1 space symbol to our output string
        inc esi ; next symbol
        dec ecx ; one less space we need to append
        jnz .loop_append_ll

    jmp .finish_write_ll ; finish our function and writing our number to output string

.finish_write_ll:
    mov eax, esi ; eax now points on next symbol to write in output string (as before function)
    ret ; finish our function
