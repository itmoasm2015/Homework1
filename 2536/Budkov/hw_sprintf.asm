global hw_sprintf

section .text

ZERO   equ 1 << 0  ; show zeroes
PLUS   equ 1 << 1  ; show plus sign
MINUS  equ 1 << 2  ; show minus sign
SPACE  equ 1 << 3  ; print spaces
LLONG   equ 1 << 4 ; 64-bit type
WIDTH  equ 1 << 5  ; set width of the number
SIGN   equ 1 << 6  ; negative number 

%define DEG 2147483648

; test Flag
%macro sfl 1            
     or ch,(%1)
     jmp .parsePercent1
%endmacro

; set Flag
%macro setFlag 0
        mov cl,('+')
        test eax, DEG
        jz .testLongSize  
        test ch,(SIGN)
        jz .testLongSize
        mov cl,('-')
        test ch,(LLONG)
        jz .num_32
    .num_64:
        not eax
        not edx
        add edx, 1
        adc eax, 0
        jmp .testLongSize
    .num_32:        
        neg eax         ; abs
%endmacro


%macro takeDigits 0
     .getDigits:           
        mov ebx, eax
        mov eax, edx
        xor edx, edx
        div ecx
        xchg eax, ebx
        div ecx 
        add dl, '0'
        mov byte [esi], dl
        dec esi
        mov edx, ebx
        cmp edx, 0
        jne .getDigits
        cmp eax, 0
        je  .isSpaceRecieved
    %endmacro

       
    ; void hw_sprintf(char *out, char const *format, ...)
    ; args:
    ;   out_str -- out
    ;   ebx -- first arg
    ;   esi -- format
    hw_sprintf:
        push ebx
        push esi
        push edi
        xor ebx, ebx    
        mov edx, [esp + 20] ; format
        mov eax, [esp + 16] ; move pointer to out
        mov esi, esp
        add esi, 24         ; first arg
    .loopPercent:      ; parse percent sign
        mov cl,byte [edx]
        cmp cl,('%')       ; if percent got
        jne .end
        push edx
        xor ch, ch          ; set No Flag
        inc edx 
    .parsePercent2:
        mov cl,byte [edx]
        test ch,(LLONG)
        jnz .compareLong ; read flags
        test ch,(WIDTH)
        jnz .compareLong
        cmp cl,('0')
        je .setZero     ; set Flags
        cmp cl,('+')
        je .setPlus
        cmp cl,('-')
        je .setMinus
        cmp cl,(' ')
        je .setSpace
        cmp cl,('1')
        jl .compareLong
        cmp cl,('9')
        jle .pushSize
    .compareLong:        ; if long got
        cmp cl,('l')
        je .isLongGot
    .compareDigit:   ; parse Flags for digits
        cmp cl,('%')
        je .parsePercent3
        cmp cl,('u')
        je .unsetSignFlag
        cmp cl,('d')       ; if sign needed
        je .setSignFlag
        cmp cl,('i')
        je .setSignFlag
    .formatError:            ; skip/pop prev pos
        pop edx
        mov byte [eax], '%'
        inc edx
        inc eax
        jmp .loopPercent
    .pushSize:             ; parse Size Flag
        xor ebx, ebx        ; set size to zero
        push eax
    .untilEOF:     ; 
        mov cl,byte [edx]
        cmp cl,('0')       
        jl .compareLongLoop
        cmp cl,('9')       
        jg .compareLongLoop
        inc edx             ; get next
        push edx
        push ecx        
        mov eax, ebx
        mov ecx, 10         ; *10
        mul ecx
        pop ecx
        push ecx
        sub cl, '0'         ; get digit
        and ecx, 255        ; last 2 bits
        mov ebx, eax
        add ebx, ecx                                          
        pop ecx
        pop edx
        jmp .untilEOF
    .compareLongLoop:        ; start set Flags
        pop eax    
        or ch,(WIDTH)
        jmp .parsePercent2
    .setZero:
        sfl ZERO
    .setPlus:
        sfl PLUS
    .setMinus:
        sfl MINUS
    .setSpace:
        sfl SPACE
    .isLongGot:            ; read long
        inc edx 
        mov cl,byte [edx]
        cmp cl,('l')       
        jne .formatError
        sfl LLONG       ; set Long Flag
    .parsePercent1:   
        inc edx             ; get next
        jmp .parsePercent2  ; parse percent again
    .setSignFlag: 
        or ch,(SIGN)
    .unsetSignFlag:
        push edx
        push esi
        push ecx
        push eax
        test ch,(LLONG)
        jz .shortNum
    .LongLong:
        push dword [esi + 4]
        push dword [esi]
        jmp .sizeFunction ; get size of the number    
    .shortNum:
        push dword 0
        push dword [esi]
    .sizeFunction:        ; get size in ebx
        call sizeNum
        add esp, 8
        mov edi, eax
        pop eax
        pop ecx
        push ecx
        push edi
        push ebx
        test ch,(LLONG)
        jz .short       ; no long got
        push dword [esi + 4]
        push dword [esi]
        jmp .makeLongFlag
    .short:
        push dword 0        ; high half of number
        push dword [esi]
    .makeLongFlag:
        call writeResult   ; write result/get next args
        add esp, 16
        pop ecx
        pop esi
        pop edx
        add esi, 4          ; get next
        test ch,(LLONG)
        jz .skipLongFlag
        add esi, 4
    .skipLongFlag:
        jmp .noPercentAgain 
    .parsePercent3:
        mov byte [eax], '%'
        inc eax
        jmp .noPercentAgain 
    .noPercentAgain:
        add esp, 4
        inc edx
        jmp .loopPercent
    .end:
        mov byte [eax], cl
        inc edx             ; get next
        inc eax
        cmp cl,(0)         ; is end of line
        jne .loopPercent  
        pop edi
        pop esi
        pop ebx 
        ret
    
    ; function get size of string 
    ; arg:
    ;   ebx - size of the number
    findDigit:
        setFlag          ; enable Flags
    .testLongSize:
        test ch,(LLONG)
        jz .changeSign 
        xchg eax, edx
    .changeSign:
        test ch,(SPACE + PLUS)
        jnz .getNext
        cmp cl,('-')
        je .getNext
        jmp .skip
    .getNext:
        inc ebx
    .skip:
        mov ecx, 10     ; div 10
        mov esi, ebx
    .getDigits:       
        mov ebx, eax
        mov eax, edx
        xor edx, edx
        div ecx
        xchg eax, ebx    
        div ecx 
        mov edx, ebx
        inc esi
        cmp eax, 0
        je  .break
        jmp .getDigits
    .break:
        mov eax, esi 
        ret
     

    
    ; get 64bit format number
    ; return:
    ;   count of chars to cast to string
    sizeNum:
        push ebx
        push esi
        xor ebx, ebx
        mov eax, dword [esp + 12]
        mov edx, dword [esp + 16]
        test ch,(LLONG)
        jz .setSign
        xchg eax, edx
    .setSign:
        call findDigit
        pop esi
        pop ebx 
        ret
        
    ; print fixed length number     
    ; args:
    ;   eax -- number
    ;   ebx -- width
    ; return:
    ;   esi -- output string 
    writeResult:
        push ebx
        push eax
        mov esi, eax            ; move pointer to out
        mov edi, eax
        mov eax, dword [esp + 12]   ; high half
        mov edx, dword [esp + 16]   ; low half
        mov ebx, dword [esp + 20]
        cmp ebx, dword [esp + 24]
        jge .testLongFlag
        mov ebx, dword [esp + 24]
    .testLongFlag:
        test ch,(LLONG)
        jz .setSign
        xchg eax, edx
    .setSign:
        setFlag
    .testLongSize:
        test ch,(LLONG)
        jz .testMinusFlag 
        xchg eax, edx
    .testMinusFlag:
        push ecx
        test ch,(MINUS)
        jz .minusChar
        push esi
        mov esi, esi
        add esi, ebx
        sub esi, 1
    .spaceChar:              ; print spaces
        mov byte [esi], ' '
        dec esi
        cmp esi, edi
        jge .spaceChar
        pop esi
        add esi, dword [esp + 28]
        dec esi
        jmp .skipMinusChar
    .minusChar:
        mov esi, esi
        add esi, ebx
        sub esi, 1
    .skipMinusChar:
        mov ecx, 10                 ; div 10
        push ebx
        takeDigits
    .addZero:              ; add zeroes
        xor edx, edx
        div ecx
        add dl, '0'                ; print zero
        mov byte [esi], dl
        dec esi
        cmp eax, 0
        jnz .addZero    
    .isSpaceRecieved:
        pop ebx
        pop ecx
        test ch,(ZERO)
        push ecx
        mov ah, ' '
        jz .testSignFlag
        mov ah, '0'
    .testSignFlag:
        pop ecx
        test ch,(ZERO)
        push ecx
        jnz .skipSetting
        pop ecx
        test ch,(PLUS)
        push ecx
        jnz .setSign2
        cmp cl,('-')
        je .setSign2
        jmp .skipSetting
    .setSign2:
        mov byte [esi], cl
        dec esi
    .skipSetting:
        cmp esi, edi
        jl .returnResult
    .loop0:
        mov byte [esi], ah
        dec esi
        cmp esi, edi
        jge .loop0
        pop ecx
        test ch,(ZERO)
        push ecx
        jz .returnResult
        pop ecx
        test ch,(SPACE)   
        push ecx
        jz .notSpace
        inc esi
        mov byte [esi], ' '
        dec esi
    .notSpace:
        pop ecx
        test ch,(PLUS)
        push ecx
        jnz .setSignAfter
        cmp cl,('-')
        je .setSignAfter
        jmp .returnResult
        .setSignAfter:
        inc esi
        mov byte [esi], cl
        dec esi
    .returnResult:
        pop ecx      
        pop eax
        add eax, ebx
        pop ebx
        ret
