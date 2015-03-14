
; flags for sprintf
; LONG and SIGNED have to always be 1 and 2 respectively, otherwise things will break horribly
%define FLAG_LONG   1
%define FLAG_SIGNED 2
%define FLAG_PLUS   4
%define FLAG_SPACE  8
%define FLAG_ZERO   16
%define FLAG_MINUS  32
%define FLAG_NEG    64

; 4 for alignment reasons, real minimum is 21
%define MAX_NUMBER_LEN 24

; Every function preservers all registers except for eax, ecx and edx, as per cdecl calling convention
; Functions that return integer values return them in eax register, as per cdecl calling convention
; Every function may be exported and used in C/C++ as one would normally use them. They are not exported only because it feels better not to export them

; Unrelated note: for some reason, valgrind doesn't like 'enter' opcode, so I just replaced all of it with push ebp/mov ebp, esp
; I did'n bother to replace leave opcode, since it just works

section .rodata
long_min: db "-9223372036854775808", 0 ; yes, it's here just for dirtyhacking this case to simplify code
long_min_length: equ $ - long_min

section .text
; int hw_strlen(const char*)
; acts similar to libc strlen
hw_strlen:
    push ebp
    mov ebp, esp
    push edi
    
    mov edi, [esp + 12]
    mov edx, edi
    xor eax, eax
    mov ecx, 0xffffffff
    
    cld
    repne scasb
    mov eax, edi ; actual length is calculated by subtracting initial address from address where we ended up. and minus one, because scasb adds one extra
    sub eax, edx
    dec eax
    
    pop edi
    leave
    ret

; void hw_format(char* out, const char* in, int flags, int width)
; formats number contained in "in" according to flags and width
; writes result into out
hw_format:
    push ebp
    mov ebp, esp
    
    push edi
    push esi
    push ebx
    
    mov edi, [ebp + 8] ; out
    mov esi, [ebp + 12] ; in
    mov edx, [ebp + 16] ; flags
    mov ecx, [ebp + 20] ; width
    
    test edx, FLAG_MINUS
    jz .skip_removing_zero
    
    and edx, ~FLAG_ZERO
    
.skip_removing_zero
    mov al, byte [esi]
    
    cmp al, '-'
    jne .positive
    
    or edx, FLAG_NEG
    inc esi ; move source pointer one forward, so that it points to the beginning of number instead of the minus
    
.positive
    push ecx
    push edx
    
    push esi
    call hw_strlen
    add esp, 4
    mov ebx, eax
    
    cld ; clear direction flag here, because we will not call any other functions that can break df
    
    pop edx
    pop ecx
    
    test edx, (FLAG_PLUS | FLAG_SPACE | FLAG_NEG)
    jz .not_signed
    
    inc ebx
    
.not_signed
    cmp ebx, ecx
    jl .wide_enough
    
    mov ecx, ebx
    
.wide_enough
    sub ecx, ebx ; now ecx has required padding size
    mov ebx, eax ; restore real length from eax
    
    test edx, FLAG_MINUS | FLAG_ZERO
    jnz .skip_left_padding
    
    mov eax, ' '
    rep stosb ; fill with spaces if neither of FLAG_ZERO or FLAG_MINUS are set
    
; section outputting the sign of number, +, - or space
.skip_left_padding
    test edx, FLAG_NEG
    jz .positive2
    
    mov byte [edi], '-'
    inc edi
    jmp .sign_finish
    
.positive2
    test edx, FLAG_PLUS
    jz .no_plus
    
    mov byte [edi], '+'
    inc edi
    jmp .sign_finish
    
.no_plus
    test edx, FLAG_SPACE
    jz .sign_finish
    
    mov byte [edi], ' '
    inc edi
    
.sign_finish
    test edx, FLAG_ZERO
    jz .number_copy_loop
    
    mov al, '0'
    rep stosb ; fill with zeros if FLAG_ZERO is set
    
; section copying the number itself
.number_copy_loop
    xchg ecx, ebx ; swap string length and padding size, so that copy operates on string length
    rep movsb
    mov ecx, ebx ; 'swap' it back, we no longer care about string length
    
; number copying is done, now account for possible trailing space
    test edx, FLAG_MINUS
    jz .out
    
    mov al, ' '
    rep stosb ; fill with spaces if FLAG_MINUS is set
    
.out
    mov byte [edi], 0
    
    pop ebx
    pop esi
    pop edi
    
    leave
    ret

; void hw_uitoa(char*, uint)
; converts unsigned int32 to string
; does not much more than pass data to hw_ltoa
hw_uitoa:
    push ebp
    mov ebp, esp
    
    mov eax, [esp + 8]
    mov ecx, [esp + 12]
    xor edx, edx
    
    jmp hw_itoa.positive

; void hw_itoa(char*, int)
; converts signed int32 to string
; calls hw_ltoa to do the dirty job
hw_itoa:
    push ebp
    mov ebp, esp
    
    mov eax, [esp + 8]
    mov ecx, [esp + 12]
    xor edx, edx
    
    bt ecx, 31
    jnc .positive
    
    mov edx, 0xffffffff
    
.positive
    push edx
    push ecx
    push eax
    
    call hw_ltoa
    add esp, 12
    
    leave
    ret

; void hw_ultoa(char*, ull)
; converts unsigned int64 to string
; passes data to hw_ltoa
hw_ultoa:
    push ebp
    mov ebp, esp
    
    push ebx
    push esi
    push edi
    
    mov edx, [ebp + 16]
    mov eax, [ebp + 12]
    
    mov ecx, 1 ; ecx is used to store what exactly function was called, hw_ultoa or hw_ltoa
    
    jmp hw_ltoa.before_main_loop ; jump to place where all negative processing will be skipped

; void hw_ltoa(char*, long long)
; converts signed int64 to string
hw_ltoa:
    push ebp
    mov ebp, esp
    
    push ebx
    push esi
    push edi
    
    mov ecx, 0 ; see remark about ecx in hw_ultoa
    
    mov edx, [ebp + 16]
    mov eax, [ebp + 12]
    
    cmp edx, 0x80000000 ; dirtyhack LONG_LONG_MIN case, because the same code also converts unsigned numbers
    jne .flip_sign
    
    cmp eax, 0x00000000
    jne .flip_sign
    
    mov esi, long_min
    mov edi, [ebp + 8]
    mov ecx, long_min_length
    rep movsb
    jmp .out_no_stack
    
.flip_sign
    bt edx, 31
    jnc .before_main_loop
    
    not edx
    not eax
    add eax, 1
    adc edx, 0
    
.before_main_loop
    sub esp, MAX_NUMBER_LEN
    mov edi, esp
    
    push ecx ; save what function was called to decide on minus sign later
    
    mov esi, 10
; write a zero byte at the beginning of buffer, and later use it whin reversing the number string
    xor ecx, ecx
    xchg eax, ecx
    stosb
    xchg eax, ecx
    
.main_loop ; edx:eax: the current number
    mov ebx, eax ; ebx: save low half
    
    ; divide 0:high_half by 10
    mov eax, edx
    xor edx, edx
    
    div esi
    
    mov ecx, eax ; ecx: high half of result
    mov eax, ebx ; now divide remainder:low_half
    
    div esi
    ; eax: low half of result
    ; edx: remainder
    xchg eax, edx
    
    add eax, '0' ; store remainder to string
    stosb
    
    mov eax, edx ; move low and high halves of result to place
    mov edx, ecx
    
    test edx, 0xffffffff
    jnz .main_loop
    test eax, 0xffffffff
    jnz .main_loop
    
    ; loop finished, add minus and copy
    pop ecx ; this ecx is set differently based on whether ltoa or ultoa was called, see above
    test ecx, 1
    jnz .skip_minus ; if ultoa was called, skip the minus
    
    bt dword [ebp + 16], 31
    jnc .skip_minus
    
    mov al, '-'
    stosb
    
.skip_minus
    mov ecx, edi
    mov edi, [ebp + 8]
    
.copy_loop ; copy and reverse number from local storage to destination
    dec ecx
    mov al, byte [ecx]
    stosb
    test al, 0xff
    jnz .copy_loop
    
    add esp, MAX_NUMBER_LEN
    
.out_no_stack
    pop edi
    pop esi
    pop ebx
    leave
    ret

; void hw_sprintf(char *, const char *, ...)
; hw_sprintf as required by hw1.pdf
global hw_sprintf
hw_sprintf:
    push ebp
    mov ebp, esp
    
    push ebx
    push esi
    push edi
    
    mov esi, [ebp + 12] ; esi: source ptr
    mov edi, [ebp + 8]  ; edi: destination ptr
    
    lea eax, [ebp + 16] ; eax: ptr for arguments
    
    xor edx, edx ; edx: temp value
    
.main_loop:
    xor edx, edx
    mov dl, byte [esi] ; dl: current symbol
    
    cmp dl, '%'
    jne .normal
    
    xor ebx, ebx ; ebx: format flags
    xor ecx, ecx ; ecx: format width
    
    push esi ; save current position in format, to restore it if we get invalid format string
    
.format_loop
    inc esi
    mov dl, byte [esi]
    
    cmp dl, '+'
    je .set_plus
    
    cmp dl, '-'
    je .set_minus
    
    cmp dl, ' '
    je .set_space
    
    cmp dl, '0'
    je .set_zero
    jl .no_width
    cmp dl, '9'
    jg .no_width
    
.width_loop: ; reading width using the old and proven multiply-by-ten-and-add algorithm
    push eax
    push edx
    
    mov eax, ecx
    mov edx, 10
    mul edx
    
    pop edx
    
    sub dl, '0'
    add eax, edx
    mov ecx, eax
    pop eax
    
    inc esi
    mov dl, byte [esi]
    
    cmp dl, '0'
    jl .no_width
    
    cmp dl, '9'
    jle .width_loop
    
.no_width:
    cmp dl, 'l'
    jne .not_ll
    
    inc esi
    mov dl, byte [esi]
    cmp dl, 'l'
    jne .invalid_format ; we encountered an l not followed by l. looks pretty invalid
    
    inc esi
    mov dl, byte [esi]
    
    or ebx, FLAG_LONG
    
.not_ll
    cmp dl, '%'
    je .output_percent
    
    cmp dl, 'u'
    je .prepare_output
    
    or ebx, FLAG_SIGNED
    
    cmp dl, 'i'
    je .prepare_output
    cmp dl, 'd'
    je .prepare_output
; fall through to invalid_format if nothing was matched
.invalid_format
    pop esi
    mov dl, byte [esi]
    jmp .normal
    
.set_plus:
    or ebx, FLAG_PLUS
    jmp .format_loop
    
.set_minus:
    or ebx, FLAG_MINUS
    jmp .format_loop
    
.set_zero:
    or ebx, FLAG_ZERO
    jmp .format_loop
    
.set_space:
    or ebx, FLAG_SPACE
    jmp .format_loop
    
; 'subroutine': prepare for output and actually do output
.prepare_output
    add esp, 4 ; pop esi
    
    sub esp, MAX_NUMBER_LEN
    
    push eax
    push ecx
    
    push dword [eax + 4]
    push dword [eax]
    lea edx, [esp + 16]
    push edx
    
    mov edx, ebx
    and edx, 0x3 ; lower two bits
    
    add eax, [edx * 4 + .addtable] ; add number size according to flags
    mov [esp + 16], eax ; overwrite saved eax with improved value
    call [edx * 4 + .jumptable] ; call appropriate number-to-string function according to flags
    add esp, 12
    
    jmp .do_format
    
.jumptable ; a trick sometimes used by compilers to generate switch-case
    dd hw_uitoa
    dd hw_ultoa
    dd hw_itoa
    dd hw_ltoa
    
.addtable
    dd 4, 8, 4, 8
    
.do_format
    ; first argument (ecx) is already pushed from before
    push ebx
    lea edx, [esp + 12]
    push edx
    push edi
    call hw_format
    add esp, 16 ; this also pop ecx, about which we no longer care
    
    pop eax
    add esp, MAX_NUMBER_LEN
    
    inc esi
    
    jmp .forward_to_zero
    
.output_percent:
    add esp, 4 ; pop esi
    mov byte [edi], '%'
    inc edi
    inc esi
    jmp .main_loop
    
; this fragment skips to 0 char in output buffer
; it's put there by hw_format, so we can continue output where we should
.forward_to_zero
    mov edx, eax
    xor eax, eax
    mov ecx, 0xffffffff
    cld
    repne scasb
    dec edi
    mov eax, edx
    jmp .main_loop
    
.normal:
    mov byte [edi], dl
    inc esi
    inc edi
    
    test dl, 0xff
    jnz .main_loop
    
.return:
    pop edi
    pop esi
    pop ebx
    leave
    ret
