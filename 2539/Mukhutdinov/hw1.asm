%macro CDECL_ENTER 0
              enter 0, 0
              push  ebx
              push  esi
              push  edi
%endmacro

%macro CDECL_RET 0
              pop   edi
              pop   esi
              pop   ebx
              leave
              ret
%endmacro

global hw_uitoa, hw_itoa

section .bss
BYTE_STACK:   resb  1024
              
section .data
CONST_10:     dd    10
CONST_0:      dd    0
              
section .text

;; void hw_uitoa(int a, char* out);
;;
;; Makes string representation of an 32-bit unsigned integer
;;
;; Parameters:
;; int a -- input number
;; char* out -- where result is stored
hw_uitoa:
              CDECL_ENTER
              mov   eax, [ebp+8]    ; input number
              mov   edi, [ebp+12]   ; string address

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
              CDECL_ENTER
              mov   eax, [ebp+8]    ; input number
              mov   edi, [ebp+12]   ; string address

              xor   edx, edx
              xor   ebx, ebx
              
              cmp   eax, 0          ; Check if int is negative
              jge   .positive       ; and invert it if it is
              not   eax
              inc   eax
              inc   ebx
.positive:
              push  ebx
              call  __hw_ultoa
              pop   ebx
              test  ebx, ebx
              je    .copy
              dec   esi
              mov   [esi], byte '-'
              inc   ecx
.copy:        
              rep movsb             ; Copy esi to edi
              
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
__hw_ultoa:
              lea   esi, [BYTE_STACK+1023]
              mov   ecx, 1          ; Initial string length
              mov   [esi], byte 0        ; This is gonna be the null-terminator
              
              call  .recur          ; Recursive sub-function puts chars on stack
              ret
.recur:
              mov   ebx, eax        ; Save low half

              mov   eax, edx        ; Divide high half first
              xor   edx, edx
              div   dword [CONST_10]

              xchg  eax, ebx        ; Save the result and divide low half
              div   dword [CONST_10]

              dec   esi
              add   edx, '0'        ; Write remainder
              mov   [esi], dl       ; to a byte stack
              inc   ecx             ; as a symbol
              
              mov   edx, ebx        ; Restore the whole 64-bit quotient
              
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
              
