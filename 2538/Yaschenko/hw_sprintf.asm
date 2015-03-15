section .text

%define FLAG_SHOW_SIGN	1
%define FLAG_SPACE	2
%define	FLAG_ALIGN	4
%define	FLAG_ZERO	8
%define FLAG_IS64BIT	16
%define FLAG_IS_SIGNED 	32


%define setf(x) 	or ebx, x
%define testf(x) 	test ebx, x

; void hw_swprintf(char* out, char const* format, ...)
	global hw_sprintf

hw_sprintf:
				; save callee-saved registers
	push ebp
	mov ebp, esp

	push ebx
	push edi
	push esi

	mov edi, [ebp + 8]	; char* out (argument)
	mov esi, [ebp + 12]	; char const* format (argument)

	lea ecx, [ebp + 16]     ; pointer to 1st argument to format
	push ecx		; save pointer to 1st argument to format

.main_loop:
	lodsb			; Get next char from *format string in AL.
	cmp al, '%'		; If current char is '%', start parse flags.
	je parse_format

	cmp al, 0		; Format string ends, we're done here.
	je .return

	stosb			; Current char is regular char, so just put it to *out
	jmp .main_loop

.return:
	pop ecx
	pop esi
	pop edi
	pop ebx
	pop ebp
	ret

;;; Parses format flags and sets corresponding flags in EBX.
;;; +	FLAG_SHOW_SIGN	(always show sign)
;;; -	FLAG_SPACE	(add space if no sign)
;;; ␣	FLAG_ALIGN	(align left (or right))
;;; 0	FLAG_ZERO	(add zeros to fit min width)
parse_format:
	push esi		; Save position of '%' to return here in case if invalid format.
	xor ebx, ebx
.parse_flags_loop:
	lodsb			; Skip '%' and load next char.

	cmp al, '+'
	je .set_flag_show_sign

	cmp al, '-'
	je .set_flag_space

	cmp al, ' '
	je .set_flag_align

	cmp al, '0'
	je .set_flag_zero
	
	jmp .parse_flags_finished

.set_flag_show_sign:
	setf(FLAG_SHOW_SIGN)
	jmp .parse_flags_loop
.set_flag_space:
	setf(FLAG_SPACE)
	jmp .parse_flags_loop
.set_flag_align:
	setf(FLAG_ALIGN)
	jmp .parse_flags_loop
.set_flag_zero:
	setf(FLAG_ZERO)
	jmp .parse_flags_loop

.parse_flags_finished:
;;; stack: <last '%' position>(4) | ...

;;; Parses format width and stores it in EDX.
parse_width:
;;; Let EDX hold width value
	xor edx, edx
.parse_width_loop:
	cmp al, '0'		; If current char is not digit, we're done here.
	jl .parse_width_finished
	cmp al, '9'
	jg .parse_width_finished

	imul edx, 10	   	; Add current char to width number.
	sub al, '0'
	add edx, eax

	lodsb
	jmp .parse_width_loop
.parse_width_finished:
	push edx
;;; stack: <format width>(4) | <last '%' position>(4) | ...

;;; Parses argument bit width and sets FLAG_IS64BIT if argument is 64bit.
;;; 32 bit: no special format
;;; 64 bit: 'll' specificator
parse_size:
	cmp word [esi], 'll'
	jne .parse_size_finished
	setf(FLAG_IS64BIT)
	add esi, 2
	mov al, byte [esi]	; To make AL hold current char.
.parse_size_finished:
;;; stack: <format width>(4) | <last '%' position>(4) | ...

;;; Parses number type:
;;; 'i' or 'd'	: decimal signed	: FLAG_IS_SIGNED is set
;;; 'u'		: decimal unsigned	:
;;; '%'		: percent sign		: '%' is printed out
parse_type:
	cmp al, 'd'
	je .type_is_signed

	cmp al, 'i'
	je .type_is_signed

	cmp al, 'u'
	je .type_is_unsigned

	cmp al, '%'
	je .type_is_percent
.type_is_signed:
	setf(FLAG_IS_SIGNED)
	jmp prepare_to_output
.type_is_unsigned:
	jmp prepare_to_output
.type_is_percent:
	;; Print percent sign
	stosb
	;; Discard <format width> and <last % location> from stack.
	add esp, 8
	jmp hw_sprintf.main_loop

prepare_to_output:	

	
