section .text

%define FLAG_SHOW_SIGN	1
%define FLAG_SPACE	2
%define	FLAG_ALIGN	4
%define	FLAG_ZERO	8
%define FLAG_IS64BIT	16


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
	
	%macro parse_flg 2
	cmp al, %2
	jne %%end
	setf(%1)
	jmp .parse_flags_loop
	%endmacro

	parse_flg FLAG_SHOW_SIGN 	'+'
	parse_flg FLAG_SPACE		'-'
	parse_flg FLAG_ALIGN		' '
	parse_flg FLAG_ZERO		'0'
.parse_flags_finished:
;;; stack: <last '%' position>(4) | ...

.parse_width:
;;; Let EDX hold width value
	xor edx, edx
.parse_width_loop:
	cmp al, '0'		; If current char is not digit, we're done here.
	jl .parse_width_finished
	cmp al, '9'
	jg .parse_width_finished

	imul edx, 10	   	; Add current char to width number.
	sub al, '0'
	add edx, al

	lodsb
	jmp .parse_width_loop
.parse_width_finished:
	push edx
;;; stack: <format width>(4) | <last '%' position>(4) | ...

.parse_size:
	cmp word [esi], 'll'
	jne .parse_size_finished
	setf(FLAG_IS64BIT)
	add esi, 2
	mov al, byte [esi]	; To make AL hold current char.
.parse_size_finished:
;;; stack: <format width>(4) | <last '%' position>(4) | ...

.parse_type:
	

	
