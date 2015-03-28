global hw_sprintf

extern printf

section .text

%define offset_plus  0          ; offset for flag '+'
%define offset_space 1          ; offset for flag ' '
%define offset_minus 2          ; offset for flag '-'
%define offset_zero  3          ; offset for flag '0'
%define offset_is_ll 4          ; is our number is long long
%define offset_type 5           ; type of number: if 0, int, if 1, unsigned
%define offset_sign 6           ; sign (if int): 0 - geq 0, 1 - le 0

;;; void hw_sprintf(char *out, char const *format, ...)
hw_sprintf:
        push    ebp             ; save previous base pointer
        mov     ebp, esp        ; save new base pointer

        ;; save registers
        push    edi
        push    ebx
        push    esi

        mov     edi, [ebp+8]    ; edi - destination buffer, current symbol
        mov     esi, [ebp+12]   ; esi - source buffer, current symbol

        ;; save current argument pointer
        add     ebp, 12
        mov     [arg_pointer], ebp
        sub     ebp, 12

.start_parsing:
        xor     edx, edx        ; clear edx, we'll hold current symbol there
        mov     dl, byte [esi]  ; mov current symbol to dl
        cmp     dl, '%'         ; compare with %
        jz      .parse_control  ; if %, jmp to handler of special sequences
.regular_copy:
        movsb                   ; else just copy current char
        jmp     .end_output     ; and proceed to output

;;; Parsing section, flags in eax
.parse_special_failed:          ; what to do if sequence was incorrect
        pop     esi             ; there was a pointer to esi at seq start on the stack
        mov     dl, byte [esi]  ; mov '%' to the current char and output it
        jmp     .regular_copy   ; output
.parse_control:
        xor     eax, eax        ; eax will hold flags information
        push    esi             ; push current esi to the source line
        inc     esi             ; get next char after '%'
.parse_flags:
        mov     dl, byte [esi]  ; move current char to dl

        ;; compare the dl with flags, jump to their handlers
        cmp     dl, '+'
        jz      .parse_plus
        cmp     dl, ' '
        jz      .parse_space
        cmp     dl, '-'
        jz      .parse_minus
        cmp     dl, '0'
        jz      .parse_zero

        jmp     .parse_width    ; ended flags parsing, proceed to width parsing
.parse_plus:
        bts     eax, offset_plus ; set plus bit to eax
        inc     esi              ; proceed to next char
        jmp     .parse_flags
.parse_space:
        bts     eax, offset_space ; set space bit to eax
        inc     esi               ; proceed to next char
        jmp     .parse_flags
.parse_minus:
        btr     eax, offset_zero ; reset bit of zero (minus has higher priority)
        bts     eax, offset_minus ; set bit of minus to eax
        inc     esi               ; proceed to next char
        jmp     .parse_flags
.parse_zero:
        bt      eax, offset_minus ; check if minus flag is present
        jc      .parse_zero_left  ; if it is, proceed to next char
        bts     eax, offset_zero  ; if there's no minus flag, set zero flag
.parse_zero_left:
        inc     esi             ; proceed to next char
        jmp     .parse_flags

.parse_width:
        xor     ecx, ecx        ; ecx will accumulate width
..loop:
        ;; check, if dl is a digit
        ;; if not, parse size
        cmp    dl, '0'
        jl      .parse_size
        cmp    dl, '9'
        jg      .parse_size

        ;; save registers that are needed for computations
        push    eax
        push    edx
        push    ebx

        imul    ecx, 10         ; ecx holds previous step or zero if it's the step 0
        xor     ebx, ebx        ; clear ebx
        mov     bl, dl          ; mov current char to bl
        sub     bl, '0'         ; get the int representation
        add     ecx, ebx        ; add the number to widtth

        ;; restore registers
        pop     ebx
        pop     edx
        pop     eax

        inc     esi             ; move to next char
        mov     dl, byte[esi]   ; read new char to dl
        jmp     ..loop          ; move to loop start

.parse_size:
        cmp     dl, 'l'           ; compare current char (dl) with 'l'
        jne     .parse_type       ; if not, parse type
        cmp     byte[esi+1], 'l'  ; check if next char is 'l' too
        jne     .parse_type       ; if not, parse type
        add     esi, 2            ; if it's ok, move esi on 2 bytes next
        bts     eax, offset_is_ll ; and set 'll' flag
        mov     dl, [esi]

.parse_type:
        ;; check available options, jump to handlers if needed
        cmp     dl, 'i'
        je      .end_parsing
        cmp     dl, 'd'
        je      .end_parsing
        cmp     dl, 'u'
        je      ..parse_type_u
        cmp     dl, '%'
        je      ..parse_type_procent

        ;; if current char satisfies no available option, handle error
        jmp     .parse_special_failed ;
..parse_type_u:
        bts     eax, offset_type ; set type flag to 'unsigned'
        jmp     .end_parsing     ; end parsing
..parse_type_procent:
        xor     eax, eax        ; clear eax
        xor     ebx, ebx        ; clear ebx
        add     esp, 4          ; clear the saved esp value
        jmp     .regular_copy   ; current dl is '%' so just print it
.end_parsing:
        add     esp, 4          ; pop the value of recovery point
.output_special:
        bt      eax, offset_type ; check if type is unsigned
        jc      .calc_real_width ; if it is, don't set sign (0 is +)
        bt      eax, offset_is_ll ; check if number is long long
        jc      ..set_ll_sign      ; if it is, set the sign for ll

        push    ebp                      ; save ebp
        mov     ebp, dword [arg_pointer] ; move current argument pointer to ebp
        bt      dword [ebp + 4], 31      ; test if 31 bit (sign bit) of low (and the only) part
        pop     ebp                      ; restore ebp
        jnc     .calc_real_width         ; if sign is 0, go calculate the width
        bts     eax, offset_sign         ; else set sign to 1
        jmp     .calc_real_width         ; calculate the width
..set_ll_sign:
        push    ebp                      ; save ebp
        mov     ebp, dword [arg_pointer] ; mov current argument pointer to ebp
        bt      dword [ebp + 8], 31      ; test the 31st bit of high part
        pop     ebp                      ; restore ebp
        jnc     .calc_real_width         ; if the 31st bit was not 1, calculate_width
        bts     eax, offset_sign         ; else set sign flag

;;; In this part, we parse argument, place each symbol of
;;; it's base-10 representation to dec_repres_str and
;;; calculate number width in symbols (then also put it to dec_repres_length)
.calc_real_width:
        ;; save registers
        push    ebx
        push    edx
        push    eax
        push    ecx
        push    ebp

        mov     ebx, eax          ; flags now in ebx
        xor     eax, eax          ; clean old flags, eax will hold lower part
        xor     ecx, ecx          ; clean ecx
        xor     edx, edx          ; clean edx, edx will hold higher part if ll
        mov     ebp, [arg_pointer] ; move current argument pointer to ebp

        ;; Copying argument to edx:eax
        bt      ebx, offset_is_ll      ; if not long, copy just lower
        jnc     .calc_not_long_move
        mov     edx, dword[ebp+8]      ; otherwise higher too
        add     dword [arg_pointer], 4 ; and set pointer on current arg 4 bytes right
.calc_not_long_move:
        mov     eax, dword[ebp+4]      ; copy lower part to eax
        add     dword [arg_pointer], 4 ; and set pointer on current arg 4 bytes right

        ;; Converting to the 2's complement form
        bt      ebx, offset_sign  ; if sign is 0, just skip converting
        jnc     .calc_width_div
        bt      ebx, offset_is_ll ; if not long, do operation only for lower
        jnc     .calc_abs_only_lower
        not     edx             ; convert higher bits
.calc_abs_only_lower:
        not     eax             ; convert lower bits
        inc     eax

        ;; Here we divide edx:eax by 10 until it's zero. Every remainder
        ;; got will be put on the stack, then popped (after computations)
        ;; and moved to dec_repres_str.
        ;; I used this: http://www.df.lth.se/~john_e/gems/gem0033.html
.calc_width_div:
        ;; save registers
        push    esi
        push    ecx             ; will hold length
        push    ebx
        push    ebp             ; will holds flags at some point

        mov     ebp, ebx        ; save flags to ebp
        mov     ebx, 10         ; save divider into ebx
        mov     esi, edx        ; save high bits in esi
        mov     ecx, esp        ; save current stack position
..big_loop:
        cmp     edx, ebx        ; will it fit to 2^32?
        jb      ..small_loop     ; if will, than proceed with lower

        xchg    eax, esi        ; save low to esi, high to eax
        xor     edx, edx        ; high = 0
        div     ebx             ; div by 10, remainder in edx
        xchg    eax, esi          ; swap back
        div     ebx
        push    edx             ; save remainder on stack
        mov     edx, esi        ; restore edx
        jmp     ..big_loop

..small_loop:
        div     ebx             ; div on 10
        push    edx             ; save remainder on stack
        xor     edx, edx        ; clear edx for next loop
        test    eax, eax        ; test if eax == 0
        jnz     ..small_loop    ; if nonnull, iterate


        xor     esi, esi            ; esi will hold cycle count
        bt      ebp, offset_zero    ; check if there is a '0' flag
        jc      ..restore_sequence  ; if it's present, skip setting sign here
                                    ; because we need sign0000num form, not 0000signnum
        bt      ebp, offset_sign    ; check if there's a minus
        jc      ..set_minus         ; if present, just add '-' to string
        bt      ebp, offset_plus    ; check if there's a '+' flag
        jc      ..set_plus          ; proceed to '+' flag handler
        bt      ebp, offset_space   ; check if there's a ' ' flag
        jnc     ..restore_sequence         ; proceed to ' ' flag handler
        mov     byte [dec_repres_str], ' ' ; move ' ' to string start
        inc     esi                        ; increase symbol counter
        jmp     ..restore_sequence
..set_plus:
        mov     byte [dec_repres_str], '+' ; move '+' to string start
        inc     esi                        ; increase symbol counter
        jmp     ..restore_sequence
..set_minus:
        mov     byte [dec_repres_str], '-' ; move '-' to string start
        inc     esi                        ; increase symbol counter
        jmp     ..restore_sequence

..restore_sequence:
        pop     eax                 ; pop the last digit from stack
        add     eax, '0'            ; transform int to ascii-digit
        mov     edx, dec_repres_str ; copy string location pointer to edx
        add     edx, esi            ; form current char position in dec_repres_str
        mov     [edx], al           ; copy digit to dec_repres_str
        inc     esi                 ; increment length counter
        cmp     ecx, esp            ; ecx holds esp before big loop, so compare them
        jnz     ..restore_sequence  ; if not equal, continue copying

        mov     [dec_repres_length], esi ; save string length

        pop     ebp
        pop     ebx
        pop     ecx
        pop     esi

        pop     ebp
        pop     ecx
        pop     eax
        pop     edx
        pop     ebx

;;; In this part, we form out string, now we have flags, width, formatted number string, its length.
.form_layout
        mov     ebx, 0                   ; counter to iterate over new string
        cmp     ecx, [dec_repres_length] ; compare width with real minimum width of number
        jle     ..loop_out               ; if less or equal, no need to make any margins
        bt      eax, offset_minus        ; check if we must insert margin on right side
        jc      ..loop_out               ; if yes, then just print number, else print left margin
        ;; print left margin
        mov     dl, ' '                  ; set default margin fill char
        bt      eax, offset_zero         ; check if '0' flag present
        jnc     ..after_zero_flag_set    ; if no, just fill the left margin
        mov     dl, '0'                  ; else set '0' char
        bt      eax, offset_sign         ; also test if we need to put sign before '000000' margin
        jnc     ..set_plus_sign_maybe    ; if our number is '-', just put '-'
        mov     byte [edi], '-'          ; put '-'
        inc     edi                      ; move to next char
        dec     ecx                      ; also decrease width by 1
        jmp     ..after_zero_flag_set
..set_plus_sign_maybe:
        bt      eax, offset_plus         ; check if '+' is really needed
        jnc     ..after_zero_flag_set    ; if not needed, print margin
        mov     byte [edi], '+'
        inc     edi
        dec     ecx
..after_zero_flag_set:
        mov     ebx, ecx                 ; move padding size (width)
        sub     ebx, [dec_repres_length] ; get the length of margin (... - real number length)
..loop_left_margin:
        mov     byte [edi], dl          ; set next char in the output to the certain margin sign
        inc     edi
        dec     ebx
        jnz     ..loop_left_margin      ; loop if margin is not over

        xor     ebx, ebx                ; reset the counter for ..loop_out

        ;; output the number
..loop_out:
        mov     edx, ebx            ; move current counter (shift) to edx
        add     edx, dec_repres_str ; add real address of string to this shift
        mov     dl, byte [edx]      ; move the desired byte to dl
        mov     [edi], dl                      ; print char to destination
        inc     edi                            ; move to next destination char
        inc     ebx                            ; increment counter
        cmp     ebx, dword [dec_repres_length] ; compare current length of number with real
        jb      ..loop_out

        ;; print right margin
        cmp     ecx, [dec_repres_length] ; compare width with real minimum width of number
        jle     .special_sequence_end    ; if less or equal, no need to make any margins
        bt      eax, offset_minus        ; check if we must insert margin on right side
        jnc     .special_sequence_end    ; if not, then just fill right side with ' '
        mov     ebx, ecx                 ; get width to ebx
        sub     ebx, [dec_repres_length] ; get margin size
..loop_right_margin:
        mov     byte [edi], ' ' ; move the ' ' to destination
        inc     edi             ; increment the destination
        dec     ebx             ; decrement counter of written chars
        jnz     ..loop_right_margin


;;; The sequence processing is over. There are some clearups here.
.special_sequence_end:
        ;; restore variables
        xor     eax, eax
        xor     ebx, ebx
        inc     esi
        mov     dl, [esi]
        jmp     .start_parsing
.end_output:
        test    dl, dl
        jnz     .start_parsing
.end:


        ;; restore registers (cdecl)
        pop     esi
        pop     ebx
        pop     edi

        mov     esp, ebp
        pop     ebp
        ret


section .bss
arg_pointer:            resw 2  ; the pointer to current argument
dec_repres_str:         resb 30 ; the number string itself (e.g. "-1241414")
dec_repres_length:      resw 2  ; the length of previous string
