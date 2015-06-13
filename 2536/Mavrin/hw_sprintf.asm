global hw_sprintf

%define plus 1<<0
%define align_left 1<<1
%define space 1<<2
%define long_long 1<<3
%define zero_padding 1<<4
%define unsigned 1<<5
%define is_neg 1<<6

%define set_flag(f) or ebx, f
%define test_flag(f) test ebx, f

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
  xor ecx, ecx
  xor ebx, ebx

  
  
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
  jmp .parse_flags
  
.set_zero:
  set_flag(zero_padding)
  jmp .parse_flags
  

  

.go_to_parse_width:
  cmp byte [esi], '0'
  jb .get_size
  cmp byte [esi], '9'
  ja .get_size
  xor eax, eax
  xor edx, edx
  jmp .parse_width
    
  
.parse_width:
  ; finish if symbol is not digit
  mov dl, byte [esi]
  sub dl, 48
  add eax, edx
  inc esi 
  cmp byte [esi], '0'
  jb .get_size
  cmp byte [esi], '9'
  ja .get_size
  imul eax, 10
  jmp .parse_width
  
  
.get_size:
  ; check if "long long"
  cmp word [esi], 'll'
  je .set_long_long
  jmp .get_type
  
.set_long_long:
  set_flag(long_long)
  add esi, 2
  jmp .get_type
  

.get_type:
  cmp byte [esi], 'u'
  je .set_unsigned
  cmp byte [esi], 'd'
  je .parse_arg
  cmp byte [esi], 'i'
  je .parse_arg
  cmp byte [esi], '%'
  je .go_to_print_percent_sign
  jmp .illegal_format_sequence
  
.set_unsigned:
  set_flag(unsigned)
  jmp .parse_arg
  
; print '%' and return to reading format string
.go_to_print_percent_sign:
  pop edx
  xor ebx, ebx
  xor edx, edx
.print_percent_sign:
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
  push esi ;save esi until best times
  mov [edi],eax ; save width into esi
  ; long long int has another parser
  test_flag(long_long)
  jnz .parse_long_arg
  
  mov eax, [ebp] ; get argument
  add dword ebp, 4 ; go to next argument
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
  inc ecx 
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
  inc ecx 
  cmp eax, 0 ; do while eax > 0
  jne .parse_64_num
  jmp .before_print_number
  
.before_print_number:
  mov esi, [edi]
  mov [edi], dword 0
  sub esi, ecx ; find length for padding
  cmp esi, 1 ; if padding is require
  jg .print_padding
  jmp .print_sign
  
  
  
.print_padding: ; if we should align right, print padding now(else we'll do it later)
  test_flag(align_left)
  jnz .print_sign
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
  test_flag(unsigned) ; unsigned => go to special part
  jnz .unsigned_case
  test_flag(is_neg) ; negative => print minus
  jnz .print_minus
  test_flag(plus) ; sign is required always => print plus
  jnz .print_plus
  jmp .print_number
  
.unsigned_case:
  ; if sign is required always => print plus
  test_flag(plus)
  jnz .print_plus
  cmp esi, 1; if we have a space for padding
  je .print_one_padding_symbol
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
  





