extern printf

global hw_sprintf

section .text

; Добавляет на стек регистры, переданные в аргументах, в прямом порядке
%macro mpush 1-*
	%rep %0
    	push %1
		%rotate 1
	%endrep
%endmacro

; Забирает регистры, переданные в аргументах, в обратном порядке
%macro mpop 1-*
	%rep %0
		%rotate -1
    	pop %1
	%endrep
%endmacro

; Обнуляет все регистры, переданные в аргументах
%macro mzero 1-*
	%rep %0
		xor %1, %1
		%rotate 1
	%endrep
%endmacro

hw_sprintf:
	mpush esi, edi
	mov esi, [esp + 12]
	mov edi, [esp + 16]
	mzero edx
.parse:
	cmp byte [edi], 0
	je .finish
	
		
.finish:
	mpop esi, edi		
	ret

section .bss
	return_address:		resd 1

section .data
	intFormatNewLine: 	db '%d', 10, 0
	intFormatSpace:   	db '%d ', 0
	stringFormat:     	db '%s', 10, 0
