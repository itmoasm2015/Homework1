global hw_sprintf

section .text

CONTROL_FLAG        equ  1              ;%  short name - C_flag
SIGN_FULL_FLAG      equ  1 << 1         ;+  short name - SF_flag
LEFT_ALIGN_FLAG     equ  1 << 2         ;-  short name - LA_flag
FILL_ZERO_FLAG      equ  1 << 3         ;0  short name - FZ_flag
ONLY_MINUS_FLAG     equ  1 << 4         ;   short name - OM_flag
LONG_FLAG           equ  1 << 5         ;ll short name - L_flag
SIGNED_NUM_FLAG     equ  1 << 6         ;id short name - SN_flag
REVERTED_SIGN_FLAG  equ  1 << 7         ;   short name - RS_flag


	;;  SPRINTF FUNCTION		
	;; TAKES
	;; 	edi - output stream address
	;;	esi - format stream address
	;; 	ebp - current number address
	;; USES
	;; 	ebx - flags (bh) and current character
	;; 	edx - width (if present)
	;; 	ecx - start of the current control sequence
	;; OUTS
	;; 	edi - buffer filled with the string formatted acording to the format string
hw_sprintf:         push ebp
                    push esi
                    push edi
                    push ebx

		    xor eax, eax
                    xor ebx, ebx
                    xor edx, edx
                    xor ecx, ecx

                    mov edi, [esp + 20]     ; edi = out
                    mov esi, [esp + 24]     ; esi = format
                    lea ebp, [esp + 28]     ; ebp = nums

.char_matching      mov bl, byte [esi]      ; write the next format char to bl
                    cmp bl, '%'             ; and start comparing process
                    jne .read_control_seq   
                    jmp .set_C_flag

.read_control_seq   test bh, CONTROL_FLAG
	            jz .print_char
		    cmp bl, '+'
                    je  .set_SF_flag
                    cmp bl, '-'
                    je  .set_LA_flag
                    cmp bl, ' '
                    je  .set_OM_flag
                    cmp bl, '0'
                    je  .set_FZ_flag
                    cmp bl, 'u'
                    je  .print_unsigned
                    cmp bl, 'i'
                    je  .print_signed
                    cmp bl, 'd'
                    je  .print_signed
                    cmp bl, 'l'
                    je  .try_set_L_flag
                    cmp bl, '0'
                    jg  .try_set_width
                    jmp .print_as_is

.next_char          cmp bl, 0
                    je  .after_all
                    inc esi
                    jmp .char_matching

.after_all          inc edi
	            mov byte[edi], 0 
		    pop ebx
                    pop edi
                    pop esi
                    pop ebp
                    ret


;Flags setters
;set the value of the chosen flag and do related tasks


	;;  Sets CONTROL FLAG if it wasn't or prints incorrect control seq if it was. Stores the position of the start of the current contorl sequence in ecx
.set_C_flag         test bh, CONTROL_FLAG
                    jnz .print_as_is
	            mov ecx, esi
                    or  bh, CONTROL_FLAG
                    jmp .next_char

	;;  Sets '+' flag if it wasn't or writes incorrect control sequence 
.set_SF_flag        test bh, SIGN_FULL_FLAG
                    jnz .print_as_is
                    or bh, SIGN_FULL_FLAG
                    jmp .next_char

	;; -//- for ' ' flag
.set_OM_flag        test bh, ONLY_MINUS_FLAG
                    jnz .print_as_is
                    or bh, ONLY_MINUS_FLAG
                    jmp .next_char
	
	;; -//- for '-' flag
.set_LA_flag        test bh, LEFT_ALIGN_FLAG
                    jnz .print_as_is
                    or bh, LEFT_ALIGN_FLAG
                    jmp .next_char

	;; -//- for '0' flag
.set_FZ_flag        test bh, FILL_ZERO_FLAG
                    jnz .print_as_is
                    or bh, FILL_ZERO_FLAG
                    jmp .next_char

	;; compare next symbol with current (= 'l') and -//- for 'll' flag if they are equal
.try_set_L_flag     cmp [esi+1], bl
                    jne .print_as_is
                    test bh, LONG_FLAG
                    jnz .print_as_is
                    or  bh, LONG_FLAG
	            inc esi
                    jmp .next_char

	;; determine whether we've found width or not
.try_set_width      cmp bl, '9'
                    jg  .print_as_is
                    cmp edx, 0
                    jne .print_as_is
                    jmp .read_int

;read functions
	
	;; reads int from input buffer and stores it to edx 
	;; TAKES
	;; 	esi - input buffer address
	;; OUTS
	;; 	edx - int we've read

.read_int           push ebx
                    xor eax, eax
.loop_read_int      mov ebx, 10
                    mul ebx
                    xor ebx, ebx
                    mov bl, byte [esi]
                    sub ebx, '0'
                    add eax, ebx
                    inc esi
                    cmp byte [esi], '9'
                    jg .after_read_int
                    cmp byte [esi], '0'
                    jge .loop_read_int
.after_read_int     mov edx, eax
                    pop ebx
                    jmp .char_matching
                     

;Print functions

	;; writes control sequence 'as is' from it's start (used for incorrect sequence printing)
	;; TAKES
	;; 	ecx - start adress of the cuttent control sequence
	;; 	edi - output buffer address
.print_as_is        mov bl, byte [ecx]
                    mov [edi], bl
                    inc edi
                    inc ecx
                    cmp ecx, esi
                    jbe .print_as_is
                    xor ecx, ecx
                    xor bh, bh
                    jmp .next_char

	;; outs one char. Used for writing non-control sequences
	;; TAKES
	;; 	ebx - current character (bl)
.print_char	    mov [edi], bl
		    inc edi
		    jmp .next_char
	
	;; sets 'signed' flag. Used for sign and module separate output
	;; TAKES
	;; 	ebx - flags (bh)
	
.print_signed       or bh, SIGNED_NUM_FLAG
                    jmp .print_unsigned

	;; determines type of the number and uses the proper output function
	;; TAKES
	;; 	ebx - flags (bh)
.print_unsigned     test bh, LONG_FLAG
                    jnz print_long
                    jmp print_int


	;; prints long long to out buffer
	;; TAKES
	;; 	ebp - address of the long number
	;; 	edi - out buffer
	;; 	ebx - flags
	;; USES
	;; 	eax, ecx, edx - temporary variables
print_long:         push edx                
                    push ebx               
                    xor ebx, ebx            
                    mov eax, [ebp]          ; load lower and higher parts
                    mov edx, [ebp + 4]      ; of the number to (EDX:EAX)
                    mov ecx, 10
	            mov ebx, dword[esp+4]
                    test bh, SIGNED_NUM_FLAG
                    jz .stage1	; if not signed, print as-is
                    cmp edx, 0	; or, if signed and negative,
                    jl .revert_sign ; revert sign and print as positive
	
.stage1             xor ebx, ebx ; Length of the number calculating.
.stage1_loop:       push eax
                    mov eax, edx
                    xor edx, edx
                    div ecx                 
                    xchg eax, [esp]        
                    div ecx                 
                    pop edx                 
                    inc ebx
                    test eax, eax
                    jnz .stage1_loop
                    test edx, edx           
                    jnz .stage1_loop
                    push .stage2
	            mov ecx, ebx
                    jmp print_left_part       ; outs possible left part (sign, zeroes, spaces)
	;; Outs module. Algorithm assumes the fact that that (EDX:EAX) % 10 is equal to (6 * (EAX % 10) + EBX % 10) % 10. It's used for separate EDX and EAX processing
.stage2:            lea edi, [edi + ebx]
                    mov ecx, 10
.loop_stage2:       dec edi
                    mov byte [edi], '0'
                    mov eax, [ebp + 4]      
                    xor edx, edx            
                    div ecx                 
                    lea eax, [edx * 3]
                    lea eax, [eax * 2]     
                    push eax               
                    xor edx, edx
                    mov eax, [ebp]
                    div ecx
                    pop eax
                    lea eax, [eax + edx]    ; al  = (2^32 * EDX + EAX) % 10 = (EDX:EAX) % 10
                    mov al, [rem_table + eax]
                    add [edi], al
                    mov eax, [ebp]
                    mov edx, [ebp + 4]
                    push eax
                    mov eax, edx
                    xor edx, edx
                    div ecx
                    xchg eax, [esp]
                    div ecx
                    pop edx
                    mov [ebp], eax
                    mov [ebp + 4], edx      
                    test eax, eax
                    jnz .loop_stage2
                    test edx, edx           
                    jnz .loop_stage2
.stage3:            lea edi, [edi + ebx]
                    push .after_all
                    mov eax, dword [esp + 8]
	            test ah, LEFT_ALIGN_FLAG
                    jnz print_right_part    ; outs possible right spaces
                    add esp, 4
.after_all:         add ebp, 8              
                    pop ebx
                    pop edx
	            xor bh, bh
	            xor edx, edx
                    jmp hw_sprintf.next_char

.revert_sign:       neg edx
                    neg eax
                    sbb edx, 0
                    mov [ebp], eax
                    mov [ebp + 4], edx
                    or byte [esp + 4], REVERTED_SIGN_FLAG
                    jmp .stage1


	;; prints integer according to flags
	;; TAKES
	;; 	ebp - address of the integer
	;; 	ebx - flags
	;; 	edi - output buffer
	;; USES
	;; 	edx, eax, ecx - temp variables
print_int           push edx                ;Width (stored in [esp+4]
                    push ebx                 ;Flags (stored in [esp]
                    mov ecx, dword[esp]
	            test ch, SIGNED_NUM_FLAG ;Looks simular with long-long prining. Negates number if it's negative and prints sign and flag separately
                    jz  .stage1             
                    cmp dword[ebp], 0
                    jl  .revert_sign
	
	;; Calculates length of the number and stores it in ecx
.stage1             mov eax, [ebp]
                    xor ecx, ecx
                    mov ebx, 10
	            
.loop_stage1        xor edx, edx
	            div ebx
                    inc ecx
                    cmp eax, 0
                    jg  .loop_stage1
		    xor edx, edx
	
	;; prints sign, spaces and zeros, if needed.
                    push .stage2
                    jmp print_left_part
	;; prints module of the number. Trivial algorithm.
.stage2
                    lea edi, [edi+ecx]
	            mov eax, [ebp]
                    mov ebx, 10
                    xor ecx, ecx
		    xor edx, edx
.loop_stage2        
	            inc ecx
	            dec edi
                    mov byte [edi], '0'
                    div ebx
                    add byte [edi], dl
	            xor edx, edx
	            
                    cmp eax, 0
                    jg .loop_stage2
		    
                    lea edi, [edi+ecx]
                    push .stage3
                    mov eax, dword[esp+4]
	            test ah, LEFT_ALIGN_FLAG
                    jnz print_right_part ;prints right spaces if needed
                    add esp, 4

	;;  final stage. Restores registers and cleans flags
.stage3             add ebp, 4
                    pop ebx
                    pop edx
                    xor bh, bh
                    xor edx, edx
                    jmp hw_sprintf.next_char

	;; reverts sign of the number
	;; TAKES
	;;	 ebp - adress of the number needs to be negated 
.revert_sign        mov ecx, dword[esp]
	            or ch, REVERTED_SIGN_FLAG
                    mov [esp], ecx
	            mov ecx, dword[ebp]
	            neg ecx
	            mov dword[ebp], ecx
                    jmp print_int.stage1

	;; outs sign, spaces and zeroes before number according to the flags
	;; USES
	;; 	ecx - length of the number
	;; 	esp - flags
	;; 	edi - address of the output buffer
print_left_part     add esp, 4
	            sub [esp+4], ecx
	            mov eax, dword[esp]
	            test ah, REVERTED_SIGN_FLAG | SIGN_FULL_FLAG | ONLY_MINUS_FLAG
                    jnz .reserve_sign_place ;reserves one position for sign if needed
.after_reservation  test ah, LEFT_ALIGN_FLAG | FILL_ZERO_FLAG
                    jz .print_left_spaces
.print_sign         test ah, REVERTED_SIGN_FLAG ;prints sign if needed
                    jnz .print_minus
                    test ah, SIGN_FULL_FLAG
                    jnz .print_plus
                    test ah, ONLY_MINUS_FLAG
                    jnz .print_space
.try_print_zeroes   test ah, LEFT_ALIGN_FLAG
                    jz  .print_zeroes
.to_ret             sub esp, 4
	            ret
	


	;; Helpers for left part printing
	
.reserve_sign_place dec dword[esp+4]
                    jmp .after_reservation

	;; Prints spaces in amount of [esp+4]
.print_left_spaces  mov edx, [esp+4]
.print_ls_loop      cmp edx, 0
                    jle .print_ls_after
                    mov byte [edi], ' '
                    inc edi
                    dec edx
                    jmp .print_ls_loop
.print_ls_after     mov dword [esp+4], 0
                    jmp .print_sign

	;; prints sign
.print_plus         mov byte[edi], '+'
                    inc edi
                    jmp .try_print_zeroes

.print_minus        mov byte[edi], '-'
                    inc edi
                    jmp .try_print_zeroes

.print_space        mov byte[edi], ' '
                    inc edi
                    jmp .try_print_zeroes

	;; Prints zeroes in amount of [esp+4]
.print_zeroes       mov edx, [esp+4]
.print_zeroes_loop  cmp edx, 0
                    jle .print_z_after
                    mov byte [edi], '0'
                    inc edi
                    dec edx
                    jmp .print_zeroes_loop
.print_z_after      mov dword [esp+4], 0
                    jmp .to_ret

	;; Prints right part of the sequence (spaces), if needed
print_right_part    mov edx, [esp+8]
.right_part_loop    cmp edx, 0
                    jle .right_part_final
                    mov byte [edi], ' '
                    inc edi
                    dec edx
                    jmp .right_part_loop
.right_part_final   ret


	

section .rodata
	;; it uses in long long division 
rem_table           db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
                    db 0, 1, 2, 3
