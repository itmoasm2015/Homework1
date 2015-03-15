global hw_sprintf

;It is very pretty and useful macros
%macro mpush 1-* 
    %rep %0 
        push %1 
        %rotate 1 
    %endrep 
%endmacro

; mpop is reverse to mpush
; mpush a, b, c
; mpop a, b, c 
; this commands do what we want
%macro mpop 1-*
    %rep %0
        %rotate -1
        pop %1
    %endrep
%endmacro


%macro zero 1
    xor %1, %1
%endmacro

; save and restore all registers, that we need to save, before call with cdecl
%xdefine cdecl_push mpush eax, ecx, edx
%xdefine cdecl_pop mpop eax, ecx, edx

; allocates bytes on stack
%macro allocate 1
    sub esp, %1
%endmacro

; reverse of previos macro
%macro free 1
    add esp, %1
%endmacro

; here we have a flag in bss section for our numbers
; and this command tests it for something
%macro test_flag 1
    test dword [flags], %1
%endmacro

;set our flags
%macro set_flag 1
    or dword [flags], %1
%endmacro


%macro clear_flags 0
    mov dword [flags], 0
%endmacro

;flags...
%assign ALWAYS_SIGN_FLAG 1 << 0
%assign LL_FLAG 1 << 1
%assign NEGATIVE_VALUE_FLAG 1 << 2
%assign DASH_FLAG 1 << 3
%assign UNSIGNED_SPECIFICATION_FLAG 1 << 4
%assign ZERO_FILL_FLAG 1 << 5
%assign SPACE_FLAG 1 << 6 
%assign WIDTH_FLAG 1 << 7
%assign PERCENTAGE_SIGN_FLAG 1 << 8


section .text

; void (hw_sprintf(char *buf, const char *format, ...)
hw_sprintf:
    enter 0, 0 
    mpush ebx, edi, esi;we can't touch them, because of cdecl
    mov edi, [ebp + 8]; out
    mov esi, [ebp + 12]; format
    allocate 16
    
    %define save_point [ebp - 4]; if we fail, we will copy string from here
    %define width [ebp - 8]; width of our current number
    %define pointer_to_args [ebp - 12] ;it is a pointer to args of hw_sprintf
    %define cur_abs_number_length [ebp - 16]; length of absoluite value of our current number
    
    mov ebx, ebp
    add ebx, 16
    mov pointer_to_args, ebx
    cld

    .char_proc: ;processing char
	cmp byte [esi], 0 ;is it an end of the format string?
	jne .not_end
	movsb	;store '\0'
	jmp .ending ;jmp to end stage
	.not_end        
	cmp byte [esi], '%';is it percentage?
        je .preprocessing_flags
        movsb ;no, it is not percentage, just copy it
    jmp .char_proc

%macro proc_flag 2 ;it is a simple switch
    cmp byte [esi], %1
    jne %%next_switch
    set_flag %2
    inc esi
    jmp .processing_flags
    %%next_switch:
%endmacro

%macro proc_flags 2-*
    %rep (%0 / 2)
        proc_flag %1, %2
        %rotate 2
    %endrep
%endmacro

    .preprocessing_flags:
        clear_flags ;we don't want to see some trash from previos flags
        mov save_point, esi ;we should remember this for future..
        inc esi; skip %

    .processing_flags:
        proc_flags '+', ALWAYS_SIGN_FLAG,\
            '-', DASH_FLAG,\
            ' ', SPACE_FLAG,\
            '0', ZERO_FILL_FLAG
    ;it is a one string command to process all flags. this cycle repeats, until we have flags
    
    mpush edx, eax, ebx ;we will spoil some registers
    .width_init_proc: ;string to int, asuume, that width can't be more than 2^31 - 1
    mov eax, 0 ;width
    mov ebx, 10 ;multiplier
    
    .width_proc:
    cmp byte [esi], '0'; is it less than zero digit?
    jl .width_end
    cmp byte [esi], '9'; maybe you are greater, than nine digit?
    jg .width_end
    ;okay, you have passed.
    mul ebx; eax*10
    zero dl
    mov dl, [esi]
    sub dl, '0'
    add eax, edx ; eax + new digit
    inc esi ;next char
    jmp .width_proc
    
    .width_end:
    mov width, eax ;save our width for future
    cmp dword width, 0
    je .no_width
    set_flag WIDTH_FLAG;we have width
    
    .no_width:
    ;nothing
    mpop edx, eax, ebx ;restore our register
    
    .try_ll: ;try to find ll modifier
        cmp byte [esi], 0 ;we see an end, but we will want to know type. It is bad;
        je .fail
        
        cmp byte [esi], 'l' ;first l
        jne .type_spec
        
        inc esi
        cmp byte [esi], 'l' ;second l
        jne .fail ;no second ll o_O Maybe it's a joke.
        
        inc esi
        set_flag LL_FLAG ; we have got it
        jmp .type_spec ;now we are interesting in type.
        
%macro type_check 2 ;simple switch for matching types and setting flags
    cmp byte [esi], %1
    jne %%next_switch
    set_flag %2
    inc esi
    jmp .print_num;it is a type, now, we have all flags, let's print our number
    %%next_switch: 
%endmacro

    .type_spec:
        cmp byte [esi], 0
        je .fail;end of the string. fail.
        type_check 'u', UNSIGNED_SPECIFICATION_FLAG
        type_check 'i', 0
        type_check 'd', 0
        type_check '%', PERCENTAGE_SIGN_FLAG
        jmp .fail;no type. fail.
    
    .fail: ;need some recovery :(  copy all characters from previous % to current char
        xchg esi, save_point
        .fail_loop:
            cmp save_point, esi;
            je .char_proc 
            movsb
            jmp .fail_loop    
    jmp .char_proc ;try again
       
    .print_num: 
        test_flag PERCENTAGE_SIGN_FLAG; if our type is %, just print it;
        jz .not_percentage
        mov al, '%'
        mov [edi], al; print it
        inc edi
        jmp .char_proc; it was easy. Continue.
    ;it is an adventure time!    
    .not_percentage:
    allocate 30 ;some lolal stack storage for my number
    mov ebx, esp; ebx now contains a pointer to our stuff
    mov ecx, pointer_to_args
    cdecl_push; we are going to call cdecl itoa. It can disappoint us.
    
    push dword [ecx] ;push low bits of our number
    add ecx, 4
   
    push dword 0 ;push high bits of our number
    test_flag LL_FLAG
    jz .after_big
    free 4;oh, it is a 64bit number;
    push dword [ecx];push again right value;
    add ecx, 4
    .after_big:
 
    mov pointer_to_args, ecx;we consume arguments. We can forget them.
    push ebx;our storage
    call itoa
    mov cur_abs_number_length, eax; it is great, that our itoa return length of number
    free 12; free arguments. ptr and long long number;
    cdecl_pop
      
    test_flag WIDTH_FLAG ;we have no width flag
    jz .without_any_width
    
    test_flag DASH_FLAG; we should add spaces after our number. Just print it now.
    jnz .without_any_width
    
    test_flag ZERO_FILL_FLAG; we should add zeros after sign, or something else
    jnz .without_any_width
   
%macro symbol_fill_and_width_cmp 1 ;this macro checks some flags, that can increase number of chars in our 
    mov ecx, 0 ;string representation of number and fill free space with something
    mov edx, 1
    test_flag (ALWAYS_SIGN_FLAG | NEGATIVE_VALUE_FLAG | SPACE_FLAG) ; oh no, some character
    cmovnz ecx, edx; now we subtract it from width that we want to fill
    sub width, ecx
    mov ecx, cur_abs_number_length
    sub width, ecx
    mov ecx, 0
    mov al, %1
    %%fill_loop:;while ecx < width, we should fill it.
        cmp dword width, ecx
        jle %%after_loop
        stosb
        inc ecx
        jmp %%fill_loop
    %%after_loop:
%endmacro  
   ;we have a width flag and no zero flag. We need to fill all free space with spaces
    symbol_fill_and_width_cmp ' '
    jmp .without_any_width; now just print number
    
    .without_any_width:; this jump was like a tiny step..

%macro check_flag_and_print 3 ;checks current flag, and stosb symbol of it representation
    test_flag %1 ;jump to specail label, in case of success
    jz %%check_failed
    mov al, %2
    stosb
    jmp %3
    %%check_failed:
%endmacro    
      
    check_flag_and_print NEGATIVE_VALUE_FLAG, '-', .zero_fill
    check_flag_and_print ALWAYS_SIGN_FLAG, '+', .zero_fill
    check_flag_and_print SPACE_FLAG, ' ', .zero_fill
   
     
    .zero_fill:
    test_flag DASH_FLAG;we have an zero, but we should ignore it, because of dash
    jnz .copy_loop
    test_flag ZERO_FILL_FLAG
    jz .copy_loop
    symbol_fill_and_width_cmp '0'
    
    .copy_loop:;and we can copy our number to output
        cmp byte [ebx], 0 ;we have good string representation, which ends with zero terminal
        je .after_copy_loop
        mov byte al, [ebx]
        stosb
        inc ebx
        jmp .copy_loop
    .after_copy_loop:
    
    
    test_flag DASH_FLAG;fill right half of emptyness
    jz .no_dash
    symbol_fill_and_width_cmp ' '
    
    .no_dash:
    
    free 30    ;free our secret storage for number
    jmp .char_proc ;again and again we should process characters, gj, we have printed id.
 
    .ending:
    free 16       ;free our tmp variables
    %undef save_point
    %undef width                                 
    mpop ebx, edi, esi ;restore registers
    leave;good bye
    ret;Nobody here




;int abs_itoa(char* buf, long long num)
;stack:
; lo
; hi
; bufptr
;returns number of digits written, excluding minus sign and writes absolute value to buf.
;General purposes function of translating all integers to string
;it looks at ll and u flags and do right things
itoa: 
    enter 0, 0
    mpush ebx, edi, esi, ecx;we shouldn't spoil them
    mov edi, [ebp + 8] ;place to write
    mov edx, [ebp + 12]; hi part
    mov eax, [ebp + 16]; low part
    mov esi, edx; another hi part
    mov ebx, 10; divisor
    mov ecx, esp; stack head. We will store our number there.
    
    test_flag LL_FLAG;process 2-compliment of negative numbers
    jz .not_long_long
        test_flag UNSIGNED_SPECIFICATION_FLAG
        jnz .big;oops, it is unsigned, let's divide it!
        cmp edx, 0
        jge .big; >= 0
        set_flag NEGATIVE_VALUE_FLAG; it is negative
        not eax
        not edx
        clc
        add eax, 1
        adc edx, 0 ;compliment
    jmp .big    
    
    .not_long_long:;we are not long long
        test_flag UNSIGNED_SPECIFICATION_FLAG
        jnz .big
        cmp eax, 0
        jge .big
        neg eax; this compliment is easy
        set_flag NEGATIVE_VALUE_FLAG
        
    .big:
        cmp edx, ebx;if edx < 10 we will fit into the eax
        jb .tiny
        xchg eax, esi; we are going to divide high part of our numer
        zero edx;just
        div ebx; divide it!
        xchg eax, esi; Okay, now, reminder of hi part and full lo part, like an Long division at paper
        div ebx
        push dx; save the last digit
        mov edx, esi; repeat it, return long part to edx.
        jmp .big; do it again
        
    .tiny: ;we have only lo part
        div ebx
        push dx
        zero edx
        cmp eax, 0 ;while eax not zero, we have something to divide.
        jne .tiny
        
    mov ebx, 0 ;count of digits
 
    .store:
        pop ax
        add al, '0'
        mov [edi], al
        inc edi
        inc ebx
        cmp ecx, esp
        jne .store
    mov byte [edi], 0 ;it is the last terminal charater
    mov eax, ebx ;eax - return value
    mpop ebx, edi, esi, ecx ;restore all registers
    leave 
    ret  
    
section .bss 
flags: resd 1
