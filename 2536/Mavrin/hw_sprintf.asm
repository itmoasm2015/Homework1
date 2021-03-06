global hw_sprintf

; this constants will be used for saving flags
; flags will be saved in ebx
%define plus 1<<0 ; '+' in format sequence
%define align_left 1<<1 ;'-' in format sequence 
%define space 1<<2 ;' ' in format sequence
%define long_long 1<<3 ;'ll' in format sequence
%define zero_padding 1<<4 ;'0' in format sequence
%define unsigned 1<<5 ;unsigned type
%define is_neg 1<<6 ;negative argument

%define set_flag(f) or bx, f 
%define test_flag(f) test bx, f 

%macro longdiv 0 ; 
;; divides edx:eax by ebx, stores the quotient in esi:eax and the remainder in edx
;; division is based on http://www.df.lth.se/~john_e/gems/gem0033.html
;; esi should be equal to edx in the beginning
;; ebx=d
;; esi=hi, edx=hi, eax=lo
mov esi, edx	; esi=hi, edx=hi, eax=lo
xchg eax, esi	; lo hi hi
xor edx, edx	; lo 0 hi
div ebx	; lo hi%d hi/d
xchg eax, esi	; hi/d hi%d lo
div ebx	; hi/d (hi%d:lo)%d (hi%d:lo)/d
%endmacro

section .text


hw_sprintf:
  push ebp
  push esi
  push edi
  push ebx
  mov edi, [esp+20] ; output buffer
  mov esi, [esp+24] ; format string
  lea ebp, [esp+28] ; first argument
  xor eax, eax
  xor ebx, ebx
  xor ecx, ecx
  xor edx, edx

  
  
.get_next: ; read and print one symbol
  cmp byte [esi], '%'
  je .go_to_parse_flags
  mov al, byte [esi] ; read a byte from format string
  mov [edi], al ; write a byte to buffer
  inc edi ; go to next byte of buffer
  test al, al ; check end of string
  je .finally
  inc esi ; go to next byte of format string
  jmp .get_next
  
.finally:
  pop ebx
  pop edi
  pop esi
  pop ebp
  ret

.go_to_parse_flags:
  push esi ; save position (need if format sequence is invalid)
  xor eax, eax
  jmp .parse_flags
  
.parse_flags:
  inc esi ; go to next position
  ; check flags
  cmp byte [esi], '+'
  je .set_plus
  cmp byte [esi], ' '
  je .set_space
  cmp byte [esi], '-'
  je .set_left
  cmp byte [esi], '0'
  je .set_zero
  jmp .go_to_parse_width 
  
; set flags
.set_plus:
  set_flag(plus)
  jmp .parse_flags
  
.set_space:
  set_flag(space)
  jmp .parse_flags
  
.set_left:
  set_flag(align_left)
  test_flag(zero_padding) ; align_left "beats" zero_padding
  jz .parse_flags
  xor ebx, zero_padding
  jmp .parse_flags
  
.set_zero:
  test_flag(align_left) ; align_left => no zero_padding
  jnz .parse_flags
  set_flag(zero_padding)
  jmp .parse_flags

.go_to_parse_width:
  xor eax, eax
  xor edx, edx
  ;if symbol is not digit - width wasn't set
  cmp byte [esi], '0'
  jl .get_size
  cmp byte [esi], '9'
  jg .get_size
  jmp .parse_width
    
  
.parse_width:
  
  mov dl, byte [esi] ; get one digit
  sub dl, 48 ;convert ASCII-symbol to true digit
  add eax, edx ;add to width value
  inc esi ;go to next symbol
  
  ; finish if symbol is not digit
  cmp byte [esi], '0'
  jl .get_size
  cmp byte [esi], '9'
  jg .get_size
  mov ecx, 10
  mul ecx ; go to next digit number
  jmp .parse_width
  
  
.get_size:
  xor ecx,ecx
  ; check if "long long"
  cmp word [esi], 'll'
  je .set_long_long
  jmp .get_type
  
.set_long_long:
  set_flag(long_long)
  add esi, 2
  jmp .get_type
  

.get_type: ; last step of parsing format string
  cmp byte [esi], 'u'
  je .set_unsigned
  cmp byte [esi], 'd'
  je .parse_arg
  cmp byte [esi], 'i'
  je .parse_arg
  cmp byte [esi], '%'
  je .go_to_print_percent_sign
  jmp .illegal_format_sequence ; if symbol is not equal to [u/d/i/%], then format sequence is illegal
  
.set_unsigned:
  set_flag(unsigned)
  jmp .parse_arg
  
; print '%' and return to reading format string
.go_to_print_percent_sign:
  pop edx
  xor edx, edx
.print_percent_sign:
  xor ebx, ebx
  mov al, '%'
  mov [edi], al
  inc esi
  inc edi
  jmp .get_next

; if sequnce is illegal, print percent and go to next symbol
.illegal_format_sequence:
  pop esi
  jmp .print_percent_sign
  
;eax - width (will be saved in memory for some time, because in long long case too many registers required)
;ebx - flags
;ecx - empty
;edx - empty
.parse_arg:
  ; delete element from stack, because sequnce is legal
  pop edx ; 
  xor edx, edx ;
  xor ecx, ecx
  push esi ;save esi until best times
  xor esi, esi
  
  ; some unobvious magic to save width(simply because i haven't just one more register)
  ; EAX - width
  mov ecx, ebx ; ECX = (0 : flags)
  mov bx,ax ; EBX = (0 : width[0..15])
  shl ebx, 16 ; EBX = (width[0..15] : 0)
  mov bx, cx ; EBX = (width[0..15] : flags)
  xor ecx, ecx ; ECX = (0 : 0)
  shr eax, 16  ; EAX = (0 : width[16..31])
  mov cx, ax ; ECX = (0 : width[16..31])
  shl ecx, 16 ; ECX = (width[16..31] : counter = 0)
  
  ; long long int has another parser
  test_flag(long_long)
  jnz .parse_long_arg
  
  mov eax, [ebp] ; get argument
  add dword ebp, 4 ; go to next argument
  test_flag(unsigned)
  jnz .parse_num
  cmp eax, 0
  jl .set_negative
  jmp .parse_num

.set_negative:
  set_flag(is_neg)
  neg eax
  jmp .parse_num
  
.parse_long_arg:
  
  mov eax, [ebp] ; get argument
  mov edx, [ebp+4]
  add dword ebp, 8 ; go to next argument
  ;mov ebp,eax
  test_flag(unsigned)
  jnz .parse_64_num
  test edx, edx
  jge .parse_64_num
  ; else number is negative
  test_flag(unsigned)
  jnz .parse_64_num
  set_flag(is_neg)
  ; special neg for long long
  not eax
  not edx
  add eax, 1
  adc edx, 0
  
  jmp .parse_64_num
  

.parse_num: ; refactor int to ASCII-symbols 
  xor edx, edx
  push esi
  mov esi, 10
  div esi ; last digit of number goes to edx
  pop esi
  add edx, 48 ; get code of digit in ASCII
  push edx ; save digit because order is upside-down
  inc cx 
  cmp eax, 0 ; do while eax > 0
  jne .parse_num
  jmp .before_print_number
  
.parse_64_num: ; MORE REGISTERS FOR GOD OF REGISTERS
  push ebx ;save flags
  mov ebx, 10
  longdiv
  pop ebx ;get flags
  add edx, 48 ; get code of digit in ASCII
  push edx ; save digit because order is upside-down
  xchg edx, esi ; return to format edx:eax
  inc cx 
  cmp eax, 0 ; do while eax > 0
  jne .parse_64_num
  jmp .before_print_number
  
.before_print_number:
  xor esi, esi
  xor eax, eax
  
  ;some unobvious magic to get saved width
  ; EBX = (width[0..15] : flags)
  ; ECX = (width[16..31] : counter)
  mov ax, cx ;EAX = counter
  shr ecx, 16 ;ECX = (0 : width[16..31])
  mov si, cx ;ESI = (0 : width[16..31])
  shl esi, 16; ESI = (width[16..31] : 0)
  mov edx, ebx; EDX = (width[0..15] : flags)
  shr edx, 16; EDX = (0 : width[0..15])
  mov si, dx; ESI = (width[16..31] : width[0..15]) = WIDTH
  
  sub esi, eax ; find length for padding
  cmp esi, 1 ; if padding is require
  mov ecx, eax
  jg .before_print_padding
  jmp .print_sign
  
  
.before_print_padding:
  test_flag(plus)
  jnz .print_padding
  test_flag(is_neg)
  jnz .print_padding
  test_flag(space)
  jz .print_padding
  ; if space_flag set and sign wasn't reqired - print a space
  mov [edi], byte ' '
  inc edi
  dec esi
  
.print_padding: ; if we should align right, print padding now(else we'll do it later)
  test_flag(align_left)
  jnz .print_sign
  test_flag(zero_padding) ; if (zero_padding) sign should be first symbol
  jnz .print_sign_first
  jmp .print_padding_loop
  
.print_sign_first:
  test_flag(plus)
  jnz .print_p
  test_flag(is_neg)
  jnz .print_m
  jmp .print_padding_loop
  .print_p:
    mov [edi], byte '+'
    inc edi
    dec esi
    jmp .print_padding_loop
  .print_m:
    mov [edi], byte '-'
    inc edi
    dec esi
    jmp .print_padding_loop
  
  
.print_padding_loop: ; print padding symbol until we can
  cmp esi, 1
  je .print_sign
  dec esi
  test_flag(zero_padding)
  jnz .print_zero
  jmp .print_space
  
.print_zero:
  mov [edi], byte '0'
  inc edi
  jmp .print_padding_loop
  
.print_space:
  mov [edi], byte ' '
  inc edi
  jmp .print_padding_loop
  
.print_sign:
  test_flag(zero_padding)
  jnz .zero_pad
  test_flag(unsigned) ; unsigned => go to special part
  jnz .unsigned_case
  test_flag(is_neg) ; negative => print minus
  jnz .print_minus
  test_flag(plus) ; sign is required always => print plus
  jnz .print_plus
  .zero_pad:
  cmp esi, 1
  jge .print_one_padding_symbol
  jmp .print_number
  
.unsigned_case:
  ; if sign is required always => print plus
  test_flag(plus)
  jnz .print_plus
  cmp esi, 1; if we have a space for padding
  jge .print_one_padding_symbol
  jmp .print_number
  
.print_one_padding_symbol:

  test_flag(align_left) ;left aligning is required => padding will be printed later
  jnz .print_number
  test_flag(zero_padding) ;print symbol which depends on type of padding
  jnz .print_one_zero
  jmp .print_one_space
  
  .print_one_zero: ;no comments, lol
  mov [edi], byte '0'
  inc edi
  jmp .print_number
  
.print_one_space:
  mov [edi], byte ' '
  inc edi
  jmp .print_number
  
.print_minus:
  mov [edi], byte '-'
  inc edi
  dec esi ;sign is taking place of one padding symbol 
  jmp .print_number
  
.print_plus:
  mov [edi], byte '+'
  inc edi
  dec esi; sign is taking place of one padding symbol
  jmp .print_number
  
.print_number: 
  cmp ecx, 0 ; do while counter > 0
  je .continue
  pop edx ; get one digit from stack
  
  mov[edi], edx ; print digit
  inc edi ; go to next byte of output buffer
  dec ecx ;counter--
  jmp .print_number

.continue:
  test_flag(align_left) ;if number was aligned left, we need a padding after it
  jnz .print_right_padding
  jmp .go_to_next
  
.print_right_padding:
  cmp esi, 0;while we have a space for padding
  jle .go_to_next
  dec esi
  jmp .print_right_space
  
.go_to_next:
  pop esi ; get saved esi
  inc esi ; go to next byte of input string
  xor ebx, ebx
  jmp .get_next

  
.print_right_space:
  mov [edi], byte ' '
  inc edi
  jmp .print_right_padding
  





