;; 15.03.2015 CTD Assembler course Homework 1 solution
;; Author: Dmitry Mukhutdinov, 2539
;;
;; General notes:
;; All the functions what have C-style signature in their comment
;; block are meant to be CDECL-compatible.
;; For a non-CDECL function: if not explicitly said, then function
;; doesn't guarantee to save any register except ESP and EBP - they are always saved

%macro CDECL_ENTER 2
              push  ebx
              push  esi
              push  edi
              enter %1, %2
%endmacro

%macro CDECL_RET 0
              leave
              pop   edi
              pop   esi
              pop   ebx
              ret
%endmacro

%macro JCOND 4
	      cmp   %2, %3
	      j%1   %4
%endmacro

%macro JIFE 3
	      JCOND e, %1, %2, %3
%endmacro

;; Definitions of control sequence parser flags
;;
;; Flags are stored in EBX register after parsing control sequence
;; (actually, they fit in BL, what gives us an opportunity to use BH for other needs)
%define FLAG_SIGN_ANYWAY        1   ; '+'
%define FLAG_PUT_WHITESPACE     2   ; ' '
%define FLAG_LEFT_ALIGN         4   ; '-'
%define FLAG_PAD_WITH_ZEROES    8   ; '0'
%define FLAG_LONG_LONG          16  ; 'll'
%define FLAG_UNSIGNED           32  ; 1 if 'u', 0 otherwise
%define FLAG_NEGATIVE           64  ; Helper flag: 1 if number being processed is negative, 0 otherwise

;; Convenience macros
%define	TEST_FLAG(fl)  test bl, fl
%define SET_FLAG(fl)   or   bl, fl
%define UNSET_FLAG(fl) and  bl, ~fl

%macro JCFLAG 3                     ; Conditional flag checking jumps
              TEST_FLAG(%2)
              j%+1  %3
%endmacro

%macro JFLAG 2
              JCFLAG nz, %1, %2
%endmacro

%macro JNFLAG 2
              JCFLAG z, %1, %2
%endmacro

global hw_sprintf, hw_ntoa

section .bss
BYTE_STACK:   resb  24              ; Temp buffer to store undigned number representation (guaranteed to fit for any long long)

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
	      lea   edx, [esp+28]   ; Store next argument address in EDX
	      xor   eax, eax        ; Reset EAX - though we use only AL to store current symbol,
				    ; we'll need full EAX to count LEA at line 127
              cld                   ; Clear direction flag
.main_loop:
              mov   al, [esi]
	      JIFE  al, 0, .finish  ; Test for null-character (end of string)

	      JIFE  al, '%', .start_parsing ; Check for control sequence beginning

              mov   [edi], al       ; Copy ordinary characters
              inc   esi
              inc   edi
              jmp   .main_loop

.start_parsing:
	      ;; Start control sequence parsing
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
;; edx -- address of current argument
;;
;; Returns:
;;
;; esi -- address of part of format string part after control sequence
;; edi -- address of the rest of the output string
;; edx -- address of next argument
__parse_sequence:
	      push  esi             ; Save current position in format string in case of parsing failure
	      xor   ebx, ebx        ; Reset flags
.flags_loop:
	      inc   esi             ; We are on '%' symbol now, go further
	      mov   al, [esi]

	      ;; Check for all possible flags
	      JIFE  al, '+', .set_p
	      JIFE  al, ' ', .set_ws
	      JIFE  al, '-', .set_minus
	      JIFE  al, '0', .set_zero

	      ;; Read width to ECX if it is present (non-present width == width 0)
	      xor   ecx, ecx
.width_loop:
	      ;; If current character is not digit, finish it
	      JCOND b, al, '0', .width_loop_finish
	      JCOND a, al, '9', .width_loop_finish

	      lea   ecx, [ecx*5]         ; Do ecx := ecx*10 + eax - '0' in two steps
	      lea   ecx, [ecx*2+eax-'0'] ; because of limitations of addressing mode
	      inc   esi
	      mov   al, [esi]
	      jmp   .width_loop

.width_loop_finish:
	      ;; Try to set 'll' flag
	      JIFE  al, 'l', .check_ll
.check_type:
	      ;; Check type
	      JIFE  al, 'u', .set_unsigned
	      JIFE  al, 'i', .write_number
	      JIFE  al, 'd', .write_number
	      JIFE  al, '%', .write_percent

.failed:
	      ;; If we didn't jumped out of there, this means that control sequence is invalid
	      pop   esi             ; Restore beginning of control seq
	      jmp   .write_percent_fail ; Write initial '%' to output and skip it
.set_p:
	      SET_FLAG(FLAG_SIGN_ANYWAY)
	      jmp   .flags_loop
.set_ws:
	      SET_FLAG(FLAG_PUT_WHITESPACE)
	      jmp   .flags_loop
.set_minus:
	      SET_FLAG(FLAG_LEFT_ALIGN)
	      jmp   .flags_loop
.set_zero:
	      SET_FLAG(FLAG_PAD_WITH_ZEROES)
	      jmp   .flags_loop
.check_ll:
	      inc   esi
	      mov   al, [esi]
	      JCOND ne, al, 'l', .failed ; If we have something except 'l' after 'l', then control sequence is invalid

	      SET_FLAG(FLAG_LONG_LONG)
              inc   esi
	      mov   al, [esi]
	      jmp   .check_type
.set_unsigned:
	      SET_FLAG(FLAG_UNSIGNED)

.write_number:
              ;; Print the number itself using hw_ntoa
              push  eax             ; Save EAX

              push  ecx             ; int minlength
              push  ebx             ; int flags
              push  edi             ; char* out
              push  edx             ; void* np (and also we'll restore EDX from there)

              call  hw_ntoa

              pop   edx             ; Restore EDX and shift it properly depending on argument type
              JNFLAG FLAG_LONG_LONG, .int
              add   edx, 4          ; Shift 4 bytes further if argument is long long
.int:
              add   edx, 4
              add   esp, 12

              mov   edi, eax        ; Shift EDI forward to the end of written string (excluding the null-terminator)
              pop   eax             ; Restore EAX
              add   esp, 4          ; Erase previous ESI record on stack
              jmp   .finish

.write_percent:
              add   esp, 4
.write_percent_fail:
	      mov   [edi], byte '%'
	      inc   edi
.finish:
	      inc   esi             ; Move ESI to the first symbol after control sequence
	      ret

;; char* hw_ntoa(void* np, char* out, int flags, int minlength);
;;
;; Makes string representation of a number, stored by address np.
;;
;; Parameters:
;; void* np -- input number address (treated as int or long depending on FLAG_LONG_LONG value in flags)
;; char* out -- where result is stored
;; int flags -- output flags. The same as contents of EBX filled by __parse_sequence.
;; int minlength -- minimum length of output. Contents should be padded to minlength with spaces or zeroes, depending on flags
;;
;; Returns:
;; Address of byte right after printed string (on the null-termitanor)
hw_ntoa:
              CDECL_ENTER 0, 0
              mov   edx, [ebp+20]   ; number pointer
              mov   edi, [ebp+24]   ; output address
              mov   ebx, [ebp+28]   ; flags
                                    ; We will fetch minlength later
              cld                   ; Clear direction flag (hw_ntoa is public, so it can be used outside of hw_sprintf)
              
              mov   eax, [edx]      ; Get low half of number

              ;; Here code is branching to int preprocessing
              ;; and long long preprocessing
              JFLAG FLAG_LONG_LONG, .longlong

.int:
              xor   edx, edx

              ;; Skip all sign-related processing in case uf 'u'-flag
              JFLAG FLAG_UNSIGNED, .unsigned

              ;; Check if int is negative and invert it if it is
              bt    eax, 31         ; check the elder bit
              jnc   .unsigned

              SET_FLAG(FLAG_NEGATIVE)
              not   eax
              inc   eax
              jmp   .unsigned
.longlong:
              mov   edx, [edx+4]    ; Fetch high half

              JFLAG FLAG_UNSIGNED, .unsigned

              ;; Invert long long if it is negative
              bt    edx, 31
              jnc   .unsigned

              SET_FLAG(FLAG_NEGATIVE)
              not   eax
              not   edx
              add   eax, 1          ; it's a pity that INC doesn't set CF
              adc   edx, 0
.unsigned:
              call  __hw_ultoa

              mov   edx, [ebp+32]   ; minlength
              sub   edx, ecx        ; What we really need is the difference between real length and minlength

              ;; If any of these flags are set, real length of string would be greater by 1,
              ;; so we decrement the difference by 1.
              JNFLAG (FLAG_NEGATIVE | FLAG_SIGN_ANYWAY | FLAG_PUT_WHITESPACE), .nondec 
              dec   edx
.nondec:
              xchg  ecx, edx        ; Save real number length

              ;; Prepend with spaces if real length < minlength and no contradictory flags are set
              JFLAG (FLAG_LEFT_ALIGN | FLAG_PAD_WITH_ZEROES), .write_sign
              JCOND le, ecx, 0, .write_sign

              mov   eax, ' '
              rep   stosb
.write_sign:
              JNFLAG FLAG_NEGATIVE, .write_plus ; Write '-' in front if number was negative
              mov   [edi], byte '-'
              inc   edi
              jmp   .zeroes_in_front
.write_plus:
              JNFLAG FLAG_SIGN_ANYWAY, .write_ws ; Write '+' in front if according flag is set
              mov   [edi], byte '+'
              inc   edi
              jmp   .zeroes_in_front
.write_ws:
              JNFLAG FLAG_PUT_WHITESPACE, .zeroes_in_front ; Write ' ' in front if according flag is set
              mov   [edi], byte ' '
              inc   edi

.zeroes_in_front:
              JNFLAG FLAG_PAD_WITH_ZEROES, .copy ; Prepend with zeroes if '0' is set,
              JFLAG FLAG_LEFT_ALIGN, .copy       ; '-' flag is not set
              JCOND le, ecx, 0, .copy            ; and minlength > real length

              mov   eax, '0'
              rep   stosb
.copy:        
              xchg  ecx, edx        
              rep   movsb           ; Copy esi to edi 
                                    
              JNFLAG FLAG_LEFT_ALIGN, .return ; Append with spaces if '-' flag is set
              JCOND le, edx, 0, .return ; and minlength > real length
                                    
              xchg  ecx, edx        
              mov   eax, ' '        
              rep   stosb           
.return:                            
              mov   [edi], byte 0   ; Write null-terminator
              mov   eax, edi        ; Return current EDI
              CDECL_RET 


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
;; 
;; Saves: ebx, edi
__hw_ultoa:
              lea   esi, [BYTE_STACK+24]
              xor   ecx, ecx        ; Initial string length

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
              jne   .rec            ; halves of quotient are
.t2:                                ; zeroes, and
              test  eax, eax        ; stop recursion,
              je    .return         ; if so
.rec:
              call  .recur
.return:
              ret
