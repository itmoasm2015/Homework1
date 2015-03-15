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

%macro longdiv 0
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
  push esi ; save position (need if format sequence is invalid
  cmp byte [esi+1], '%'
  je .go_to_print_percent_sign
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
  
; print '%' and return to reading format string
.go_to_print_percent_sign:
  pop esi
  inc esi
.print_percent_sign:
  mov al, '%'
  mov [edi], al
  inc esi
  inc edi
  jmp .get_next
  

.go_to_parse_width:
  xor ecx, ecx
  mov eax, 1 ; because if last digit of width is zero, we can get a problem
  jmp .parse_width
    
  
.parse_width:
  ; finish if symbol is not digit
  cmp byte [esi], '0'
  jb .go_to_get_width
  cmp byte [esi], '9'
  ja .go_to_get_width
  inc ecx ; count digits in number
  inc esi 
  jmp .parse_width
  
.go_to_get_width:
  push esi ; save current position in format string // DONT FORGET TO POP
  xor edx, edx
  jmp .get_width
  
.get_width:
  cmp ecx, 0 ;while counter!=0 read width
  je .get_size
  dec esi
  dec ecx
  ;read one digit of width
  mov dl, byte [esi]
  sub dl, 48
  add eax, edx
  cmp ecx, 0 
  je .get_size
  imul eax, 10
  jmp .get_width
  
.get_size:
  dec eax ; because eax = 1 at start of parse_width
  pop esi ; get saved position in format string
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
  jmp .illegal_format_sequence
  
.illegal_format_sequence:
  pop esi
  jmp .print_percent_sign
  
.set_unsigned:
  set_flag(unsigned)
  jmp .parse_arg
  
;eax - width -> esi
;ebx - flags
;ecx - empty
;edx - empty
.parse_arg:
  pop edx
  push esi
  xor edx, edx
  test_flag(long_long)
  jnz .parse_long_arg
  mov esi,eax
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
  mov esi,eax
  mov eax, [ebp] ; get argument
  mov edx, [ebp+4]
  add dword ebp, 8 ; go to next argument
  test_flag(unsigned)
  jnz .parse_64_num
  test edx, edx
  jge .parse_64_num
  set_flag(is_neg)
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
  
.parse_64_num:
  push ebx
  mov ebp, esi
  mov ebx, 10
  longdiv
  pop ebx
  add edx, 48 ; get code of digit in ASCII
  push edx ; save digit because order is upside-down
  xchg edx, esi
  mov esi, ebp
  inc ecx 
  cmp eax, 0 ; do while eax > 0
  jne .parse_64_num
  jmp .before_print_number
  
  
.before_print_number:
  sub esi, ecx
  cmp esi, 1
  jg .print_padding
  jmp .print_sign
  
  
  
.print_padding:
  test_flag(align_left)
  jnz .print_sign
  jmp .print_padding_loop
  
.print_padding_loop:
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
  test_flag(unsigned)
  jnz .unsigned_case
  test_flag(is_neg)
  jnz .print_minus
  jmp .print_plus
  
.unsigned_case:
  test_flag(space)
  jnz .print_one_space
  cmp esi, 1
  je .print_one_padding_symbol
  jmp .print_number
  
.print_one_padding_symbol:
  test_flag(zero_padding)
  jnz .print_one_zero
  jmp .print_one_space
  
  .print_one_zero:
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
  jmp .print_number
  
.print_plus:
  test_flag(plus)
  jz .print_one_padding_symbol
  mov [edi], byte '+'
  inc edi
  jmp .print_number
  
  
.print_number: 
  cmp ecx, 0 ; do while counter > 0
  je .continue
  pop edx ; get one digit from stack
  
  mov[edi], edx ; print digit
  inc edi ; go to next byte of output buffer
  dec ecx
  jmp .print_number

.continue:
  test_flag(align_left)
  jnz .print_right_padding
  jmp .go_to_next
  
.print_right_padding:
  cmp esi, 1
  je .go_to_next
  dec esi
  jmp .print_right_space
  
.go_to_next:
  pop esi
  inc esi ; go to next byte of input string
  jmp .get_next

  
.print_right_space:
  mov [edi], byte ' '
  inc edi
  jmp .print_right_padding
  





