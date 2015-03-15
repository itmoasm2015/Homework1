section .text

%define FLAG_SHOW_SIGN	1
%define FLAG_SPACE	2
%define	FLAG_ALIGN	4
%define	FLAG_ZERO	8


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
	je parse_flags

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

;;; Parses format flags and sets corresponding flags.
;;; +	FLAG_SHOW_SIGN	(always show sign)
;;; -	FLAG_SPACE	(add space if no sign)
;;; ␣	FLAG_ALIGN	(align left (or right))
;;; 0	FLAG_ZERO	(add zeros to fit min width)
parse_flags:
	
