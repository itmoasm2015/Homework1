section .text
        
global hw_sprintf

%define ARG(n) [ebp + (5+n) * 4]
; first arg = ARG(0)

%define DEF_VARS(n) sub esp, n * 4
%define VAR(n) [ebp - (1+n) * 4]

        
        
%macro PROLOGUE 0
        push ebp
        push esi
        push edi
        push ebx
        mov ebp, esp
%endmacro

; stack after prologue, def_vars(3)
; arg2 <-- ARG(1)
; arg1 <-- [ebp+5*4] = ARG(0)
; eip(prev)
; ebp(prev)
; esi
; edi
; ebx <-- [ebp]
; var1 <-- [ebp-4*4] = VAR(0)
; var2 <-- VAR(1)
; var3 <-- [esp]
        
%macro EPILOGUE 0
        mov esp, ebp
        pop ebx
        pop edi
        pop esi
        pop ebp
        ret
%endmacro

        

align 16
; void hw_sprintf(char *out, char const *format, ...)
hw_sprintf:
        PROLOGUE
;; local vars:
; int * arg @ VAR(0)
; const char * format @ esi
; const char * format_start @ VAR(1)
; char * out @ edi
; unsigned flags @ ebx
; int width @ VAR(2)
        DEF_VARS(3)
        cld                     ; dir flag = 0
        lea eax, ARG(2)         ; 3rd arg
        mov VAR(0), eax


        mov edi, ARG(0)        ; out
        mov esi, ARG(1)        ; format

.format_char:
;; *format == '%'
        cmp byte [esi], '%'
        je .format_control
        
        cmp byte [esi], 0       ;'\0'
;; *out++ = *format++
        movsb
        jne .format_char        ; while(*format)

        
        EPILOGUE


.format_control:
        mov VAR(1), esi 	; format_start = format
        inc esi                 ;++format
        xor eax, eax
        xor ebx, ebx            ; flags = 0


%assign F_PLUS 1 ; print '+' if F_NEGATIVE is not present
%assign F_MINUS 2 ; align to left
%assign F_SPACE 4 ; print ' ' if F_NEGATIVE is not present
%assign F_ZERO 8 ; print '0' (width - strlen(sign+num)) times if F_MINUS is not present
%assign F_LLONG 16 ; number is llong
%assign F_SIGNED 32 ; used to set F_NEGATIVE
%assign F_NEGATIVE 64 ; print '-'


.parse_flags:
        mov al, [esi]
%macro FLAG_PARSE 2     ;char, flag
	cmp al, %1
	jne %%skip_flag
        or ebx, %2
        inc esi
	jmp .parse_flags
        %%skip_flag:
%endmacro
        FLAG_PARSE '+', F_PLUS
        FLAG_PARSE '-', F_MINUS
        FLAG_PARSE ' ', F_SPACE
        FLAG_PARSE '0', F_ZERO

        
;; width - result: eax, clobbers: ecx
        call atou
        mov VAR(2), eax ; save width

        xor ecx, ecx

;; test for ll
        cmp word [esi], 'll'
        jne .parse_type
        add esi, 2
        or ebx, F_LLONG

.parse_type:

        mov cl, [esi]
        inc esi

%macro TEST_TYPE 2      ;char, label
        cmp cl, %1
        je %2
%endmacro
        TEST_TYPE 'i', .signed
        TEST_TYPE 'd', .signed
        TEST_TYPE 'u', .unsigned
        TEST_TYPE '%', .percent
;; invalid
        mov esi, VAR(1) 	;format = format_start
        movsb                   ;*out++=*format++
        jmp .format_char


.percent:
        mov [edi], cl           ;*out++='%'
        inc edi
        jmp .format_char

.signed:
        or ebx, F_SIGNED
.unsigned:
;; load number in edx:eax
        mov ecx, VAR(0) ; int32_t* ecx = &cur_arg
        mov eax, [ecx] ; int32_t eax = *ecx
        add ecx, 4 ; ecx++
        
        xor edx, edx
        
        test ebx, F_LLONG
        jz .skip_llong

        ; load edx
        mov edx, [ecx] ; int32_t edx = *(ecx++)
        add ecx, 4
.skip_llong:
; &cur_arg = ecx
        mov VAR(0), ecx

; test if number is signed and negate it
        test ebx, F_SIGNED
        jz .skip_negation
;; negate
;; compare edx (eax if 32bit) with 0
        
        test ebx, F_LLONG
        jz .compare_dword
        cmp edx, 0
        jge .skip_negation
        not edx                 ; dont negate edx if not llong (because edx=0)
        jmp .negate_dword
.compare_dword:
        cmp eax, 0
        jge .skip_negation
.negate_dword:
        not eax
        add eax, 1
        adc edx, 0              ;carry
        or ebx, F_NEGATIVE
        
.skip_negation:

; print number to temp buffer
; char tmp[20]
        sub esp, 20
        mov ecx, esp
        
; print sign if flag is set
%macro PRINT_SIGN 2 ; flag, sign
        test ebx, %1
        jz %%skip
        mov byte [ecx], %2
        inc ecx
        jmp .number_to_string
        %%skip:
%endmacro
        PRINT_SIGN F_NEGATIVE, '-'
        PRINT_SIGN F_PLUS, '+'
        PRINT_SIGN F_SPACE, ' '

.number_to_string:
; save regs
        mov VAR(1), esi ; we dont need format ptr, save it
        push edi
        push ebx

        mov edi, ecx
        call ulltoa ; clobbers all registers
        mov ecx, edi
; restore regs
        pop ebx
        pop edi
;
        mov esi, esp
; sign+number string is in [esi ... ecx]
; alignment
        sub ecx, esi ; ecx = strlen(tmp)
        
        mov eax, VAR(2)
        sub eax, ecx
; int eax= width - strlen(tmp) - amount of spaces(zeroes) to print (might be < 0)
        
        
        test ebx, F_MINUS ; output number if we are aligning to left
        jnz .out_number

; aligning to right: output spaces, then sign+number
        mov dl, ' ' ; space or zero
        
        test ebx, F_ZERO
        jz .print_space
; align with zeroes
        mov dl, '0'
; output sign if present, then zeroes, then number
        mov dh, [esi]
        cmp dh, '+'
        je .out_sign
        cmp dh, '-'
        je .out_sign
        cmp dh, ' '
        je .out_sign
        jmp .print_space ; no sign
.out_sign:
        mov [edi], dh ; *out++ = sign
        inc esi ; tmp++
        inc edi
        

        
; output spaces(or zeroes)
; while(eax >= 0) *out++ = ' '
.print_space:
        cmp eax, 0
        jle .out_number
        mov [edi], dl
        inc edi
        
        dec eax
        jmp .print_space
        
.out_number:
; copy without \0
; while(*out++ = *tmp++) {}; out--
        mov dl, [esi]
        mov [edi], dl
        inc esi
        inc edi
        test dl, dl
        jnz .out_number
        dec edi


; print spaces if we are aligning to left
        test ebx, F_MINUS 
        jz .number_done
        
.print_space2:
        cmp eax, 0
        jle .number_done
        mov byte [edi], ' '
        inc edi
        
        dec eax
        jmp .print_space2

.number_done:
        mov esi, VAR(1) ; resore format
        add esp, 20

        jmp .format_char ; process next character
        



        
;;; string to uint32
;;; in:
;;; esi - string
;;; out:
;;; esi - points to the first non-digit char
;;; eax - result (signed number)
;;; clobber: ecx
align 4
atou:
        xor eax, eax ; result
        xor ecx, ecx
.loop:
        mov cl, [esi]
        sub cl, '0'
        jb .end                 
        cmp cl, 9
        ja .end                 ; if not *esi >= '0' && *esi <= '9' goto .end

%macro MUL10 1
        lea %1, [%1 + %1*4]     ;*=5
        shl %1, 1               ;*=2
%endmacro
        
        MUL10 eax
        
        add eax, ecx
        inc esi
        jmp .loop
.end:
        ret



;;; unsigned long long to string
;;; in:
;;; edi - output string
;;; edx:eax - number
;;; out: edi - end of string (*edi == '\0')
;;; clobbers: eax, ebx, ecx, edx, esi
align 16
ulltoa:
        push ebp
        mov ebp, esp
        mov esi, 10             ;radix

;; push string to stack
.loop:
        
        mov ebx, eax ; ebx: save low half
;; divide 0:high_half by 10
        mov eax, edx
        xor edx, edx
        
        div esi                 ;edx:eax / esi
        
        mov ecx, eax    ; ecx: high half of result
        mov eax, ebx    ; now divide remainder:low_half
        
        div esi
;; eax: low half of result
;; edx: remainder    
        xchg eax, edx
        
        add eax, '0' ; 
;; push al
        dec esp
        mov [esp], al
        
        mov eax, edx ; move low and high halves of result to place
        mov edx, ecx

;; while (edx:eax != 0)
        or eax, eax
        jnz .loop
        or edx, edx
        jnz .loop

;; reverse string
;; esp -> ebp
.pop_char:
;; pop al
        mov al, [esp]
        inc esp
        stosb                   ;*out++ = al
        cmp esp, ebp
        jne .pop_char

;null termination
        mov byte [edi], 0
        
        pop ebp
        ret
