%macro CDECL_ENTER 2
              push  ebx
              push  esi
              push  edi
              enter %0, %1
%endmacro

%macro CDECL_RET 0
              leave
              pop   edi
              pop   esi
              pop   ebx
              ret
%endmacro

;; Definitions of control sequence parser flags
;;
;; Flags are stored in EBX register after parsing control sequence
%define FLAG_SIGN_ANYWAY        1   ; '+'
%define FLAG_PUT_WHITESPACE     2   ; ' '
%define FLAG_LEFT_ALIGN         4   ; '-'
%define FLAG_PAD_WITH_ZEROES    8   ; '0'
%define FLAG_LONG_LONG          16  ; 'll'
%define FLAG_UNSIGNED           32  ; 1 if 'u', 0 otherwise

global hw_sprintf, hw_uitoa, hw_itoa

section .bss
BYTE_STACK:   resb  1024

section .data
CONST_10:     dd    10
CONST_0:      dd    0

section .text

;; void hw_sprintf(char *out, char const *format, ...);
;;
;; Formats string using given format with given parameters
;;
;; Parameters:
;; char* out -- output string address
;; char const* format -- format string address
;; ... -- rest of parameters (ints or long longs)
hw_sprintf:
              CDECL_ENTER 0, 0
              mov   edi, [ebp+20]   ; output string
              mov   esi, [ebp+24]   ; format string

.main_loop:
              mov   al, [esi]
              cmp   al, 0           ; Test for null-character (end of string)
              je    .finish

              cmp   al, '%'         ; Check for control sequence beginning
              je    .start_parsing

              mov   [edi], al       ; Copy ordinary characters
              inc   esi
              inc   edi
              jmp   .main_loop
              
.start_parsing:
              inc   esi             ; Start control sequence parsing
              call  __parse_sequence
              jmp   .main_loop

.finish:
              mov   [edi], byte 0   ; Null-terminate output string
              CDECL_RET


;; __parse_sequence -- inner non-cdecl function
;;
;; Parses the control sequence and prints the output to edi 
;;
;; Takes:
;; esi -- address of beginning of the control sequence
;; edi -- output string address
;;
;; Returns:
;;
;; esi -- address of part of format string part after control sequence
;; edi -- address of the rest of the output string
__parse_sequence:
              ; TODO

              
;; void hw_uitoa(int a, char* out);
;;
;; Makes string representation of an 32-bit unsigned integer
;;
;; Parameters:
;; int a -- input number
;; char* out -- where result is stored
hw_uitoa:
              CDECL_ENTER 0, 0
              mov   eax, [ebp+20]   ; input number
              mov   edi, [ebp+24]   ; string address

              xor   edx, edx
              call  __hw_ultoa
              rep   movsb           ; Copy data from esi to edi

              CDECL_RET

;; void hw_itoa(int a, char* out);
;;
;; Makes string representation of an 32-bit signed integer
;;
;; Parameters:
;; int a -- input number
;; char* out -- where result is qstored
hw_itoa:
              CDECL_ENTER 0, 0
              mov   eax, [ebp+20]   ; input number
              mov   edi, [ebp+24]   ; string address

              xor   edx, edx

              cmp   eax, 0          ; Check if int is negative
              jge   .positive       ; and invert it if it is

              pushf                 ; Save current FLAGS to check if int is negative again later
              not   eax
              inc   eax
.positive:
              call  __hw_ultoa
              
              popf                  ; Restore FLAGS
              jge   .copy           ; Write '-' in front if number was negative
              dec   esi
              mov   [esi], byte '-'
              inc   ecx
.copy:
              rep movsb             ; Copy esi to edi

              CDECL_RET

,
;; __hw_ultoa -- inner non-cdecl function
;;
;; Produces a string out of unsigned long long
;;
;; Takes:
;; edx:eax -- input long number
;;
;; Returns:
;; esi -- output string address
;; ecx -- output string length
__hw_ultoa:
              lea   esi, [BYTE_STACK+1023]
              mov   ecx, 1          ; Initial string length
              mov   [esi], byte 0   ; This is gonna be the null-terminator

              call  .recur          ; Recursive sub-function puts chars on stack
              ret
.recur:
              push  eax             ; Save low half

              mov   eax, edx        ; Divide high half first
              xor   edx, edx
              div   dword [CONST_10]

              xchg  eax, [esp]      ; Save the result and divide low half
              div   dword [CONST_10]

              dec   esi
              add   edx, '0'        ; Write remainder
              mov   [esi], dl       ; to a byte stack
              inc   ecx             ; as a symbol

              pop   edx             ; Restore the whole 64-bit quotient

              test  edx, edx        ; Test if both
              je    .t2             ; halves of
              jmp   .rec            ; quotient are
.t2:                                ; zeroes, and
              test  eax, eax        ; stop recursion,
              je    .return         ; if so
.rec:
              call  .recur
.return:
              ret
