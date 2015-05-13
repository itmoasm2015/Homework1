global hw_atoi
global hw_sprintf

%define FLAG_PLUS  1
%define FLAG_SPACE 2
%define FLAG_MINUS 4
%define FLAG_ZERO  8

%macro initFormat 0
    mov ecx, [curFormat]             ; save in ecx curFormat
    mov edx, [format]                ; save in edx pointer to format
%endmacro

%macro initOutput 0
    mov ecx, [curOutput]             ; save in ecx curOutput
    mov edx, [output]                ; save in edx pointer to output
%endmacro


section .text

    hw_sprintf:
        mov eax, esp
        push edi
        push esi
        push ebp
        push ebx

        mov ebp, eax
        mov eax, [ebp + 4]       ; first argument
        mov [output], eax
        mov eax, [ebp + 8]       ; second argument
        mov [format], eax
        mov [curFormat], dword 0 ; curFormat = 0;
        mov [curOutput], dword 0 ; curOutput = 0;
        mov [shift],     dword 12; initialized shift
        
        .mainLoop                      
            initFormat                 ;initialized ecx edx
            cmp [edx + ecx], byte 0    ; if curFromat == /0  => end of string
            je .mainLoopEnd            ; go to finish
            cmp [edx + ecx], byte '%'  ; if format[curFormat] != '%' then lets copy this symbol to output
            je .parseToken 
                mov al, [edx + ecx]    ; al = format[curFormat]
                initOutput
                mov [edx + ecx], al    ; write one symbol from "format" to "output"
               
                inc dword [curFormat]  ; curFromat++
                inc dword [curOutput]  ; curOutput++ 


            jmp .overParseToken
            .parseToken                ; case then format[curFormat] == '%'
                mov eax, [curFormat]
                mov [posBeforeParse], eax 
                            
                inc dword [curFormat]  ; shift curFormat, before it pointed to the '%'
                call parseFlags        ; variable "flags" has been initialized 
                call parseWidth        ; variable "width" has been initialized 
                    
                call parseSize         ; variable "size" has been initialized 
                call parseType         ; variable "argType" has been initialized 

                
                cmp [argType], dword 0
                jne .ok
                    .loopStart1                        ; if something wrong, when let's copy wrong substring
                                                       ; to output string
                        mov eax, [posBeforeParse]
                        cmp [curFormat], eax           ; while (posBeforeParse != curFormat)
                        je .loopEnd1
                            mov ecx, [posBeforeParse]
                            mov edx, [format]          ; edx = pointer to format
                            mov al, [edx + ecx]        ; get format[posBeforeParse]
                            initOutput                 ; init ecx edx
                            mov [edx + ecx], al         ; write to output string
                        inc dword [curOutput]           ; curOutput++
                        inc dword [posBeforeParse]      ; posBeforeParse++
                        jmp .loopStart1
                    .loopEnd1
                jmp .overOk
                .ok
                    ;;; TODO case with %                      
                    cmp [argType], dword 3 
                    jne .normCase                        ; case then type == '%'
                        initOutput                       
                        mov [edx + ecx], byte '%'        ; mov '%' to output and ignore other flags
                        inc dword [curOutput]            ; curOutput++
                        jmp .overParseToken
                    .normCase

                    mov [numberUp],   dword 0            ; clear numberDown
                    mov [numberDown], dword 0            ; clear numberUp
                    mov ecx, [shift]                   
                    mov eax, [ebp + ecx]                 ; get 4 bytes from stack
                    mov [numberDown], eax                ; numberDown = low bit
                    add [shift], dword 4                 ; shift += 4

                    cmp [typeSize], dword 1             
                    jne .notCaseLL                       ; then type have qualifier "ll"
                        mov ecx, [shift]                  
                        mov eax, [ebp + ecx] 
                        mov [numberUp], eax              ; numberUp = significant bits
                        add [shift], dword 4             ; shift += 4
                    .notCaseLL
                    call convertToBuffer   
                         
                    mov eax, [width]                     ; eax = width
                    cmp eax, [curBuffer]                 ; whether it is necessary to fill with zero 
                    jle .emptySpace 
                        mov eax, [width]
                        sub eax, [curBuffer]
                        mov [spaceSize], eax             ; spaceSize = width - curBuffer
                    jmp .overEmptySpace
                    .emptySpace 
                        mov [spaceSize], dword 0         ; spaceSize = 0
                    .overEmptySpace

                    mov eax, [flags]
                    and eax, FLAG_MINUS
                    cmp eax, 0                           ; compare FLAG_MINUS
                    je .rightOrder                       ; if set flag '-'
                        call writeBuffer
                        call writeSpace
                        jmp .overRightOrder
                    .rightOrder                          ; if doesn't set flag '-'
                        mov edi, [curOutput]             ; save position
                        mov esi, [spaceSize]
                        call writeSpace                  ; write space sybmols
                        call writeBuffer                 ; write buffer
                        mov [spaceSize], esi             ; handle case "0000+1234"
                        mov eax, [flags]                 
                        and eax, FLAG_ZERO
                        cmp eax, 0  
                        je .notSwap                      ; if where is flag '0'
                            xor ecx, ecx
                            mov eax, [flags]
                            and eax, FLAG_PLUS 
                            add ecx, eax                 ; ecx = FLAG_PLUS

                            mov eax, [flags]
                            and eax, FLAG_SPACE
                            add ecx, eax                 ; ecx = FLAG_SPACE + FLAG_PLUS
                            
                            cmp ecx, 0
                            je .notSwap                  ; if set at least one of FLAG_SPACE, FLAG_PLUS
                                mov edx, [output]        ; when swap two symbols 
                                mov al, [edx + edi]      ; first zero 
                                mov esi, edi
                                add esi, [spaceSize]     ; and sign
                                mov cl, [edx + esi]       
                                mov [edx + esi], al      ; swap elements
                                mov [edx + edi], cl
                       
                        .notSwap  
                    .overRightOrder
                .overOk
            .overParseToken 
        
        
        jmp .mainLoop 
        .mainLoopEnd 


        initOutput
        mov [edx + ecx], byte 0                          ; set terminate symblo null
        inc dword [curOutput]                            ; curOutput ++

        pop ebx
        pop ebp
        pop esi
        pop edi
        ret


    ; this function parse flags
    ; after that all flags will be kept in variable "flags"

    parseFlags:
        mov [flags], dword 0
        .loopStart
            initFormat
            ;;;;;;;;;;;;;;;;;;;+++++++++++++++
            cmp [edx + ecx], byte '+'              ; if current symbol is '+'
            jne .notPlus                  
                or  [flags], dword FLAG_PLUS       ; change variable "flags"
                inc dword [curFormat]; 
                jmp .loopStart
            .notPlus
            ;;;;;;;;;;;;;;;;;;;    
            cmp [edx + ecx], byte ' ' ; if current symbol is ' '
            jne .notSpace
                or  [flags], dword FLAG_SPACE ; change variable "flags"
                inc dword [curFormat]; 
                jmp .loopStart
            .notSpace
            ;;;;;;;;;;;;;;;;;;; -------------
            cmp [edx + ecx], byte '-' ; if current symbol is '-'
            jne .notMinus
                or  [flags], dword FLAG_MINUS ; change variable "flags"
                inc dword [curFormat]; 
                jmp .loopStart
            .notMinus

            cmp [edx + ecx], byte '0' ; if current symbol is '0'
            jne .notZero
                or  [flags], dword FLAG_ZERO ; change variable "flags"
                inc dword [curFormat]; 
                jmp .loopStart
            .notZero

        mov eax, [flags]
        and eax, FLAG_MINUS
        cmp eax, 0
        je .finish                           ; handle case when both (FLAG_ZERO and FLAG_MINUS) flags are set
            mov eax, [flags]
            and eax, FLAG_ZERO
            cmp eax, 0
            je .finish
                xor [flags], dword FLAG_ZERO  ; FLAG_ZERO <= 0

        .finish

        ret

    ; this function 
        
    parseWidth:
        push esi
        push edi 
        mov [width], dword 0                      ; width = 0

        .loopStart
            initFormat
            cmp [edx + ecx], byte '0'             ; if current symbol < '0' then break 
            jb .loopEnd
            cmp [edx + ecx], byte '9'             ; if current symbol > '9' then break 
            ja .loopEnd

            mov edi, [width]
            imul edi, 10          ; edi *= 10
            xor eax, eax          ; eax = 0

            mov al, [edx + ecx]   ; al = format[curFormat]
            sub al, '0'           ; al = format[curFormat] - '0'
            add edi, eax          ; edi += digit 

            mov [width], edi      ; write down
            inc dword [curFormat] 
            jmp .loopStart
        .loopEnd

        pop edi
        pop esi
        ret

    ; set typeSize = 1, if and only if next sybmols equal "ll"

    parseSize:
        mov [typeSize], dword 0
       
        initFormat
        cmp [edx + ecx], byte 'l'
        jne .notLong                               ; check first symbol
            cmp [edx + ecx + 1], byte 'l'          
            jne .notLong                           ; check second symbol
                mov [typeSize], dword 1            
                add dword [curFormat], 2           ; curPos += 2

        .notLong

        ret

    parseType:
        initFormat
        mov [argType], dword 0     ; argType = 0 
        cmp [edx + ecx], byte 'u'  ; parse U 
        jne .notU 
            mov [argType], dword 1 ; argType = 1 
            inc dword [curFormat]
            jmp .finish
        .notU
        
        cmp [edx + ecx], byte 'i'  ; parse I
        jne .notI 
            mov [argType], dword 2 ; argType = 2
            inc dword [curFormat]
            jmp .finish
        .notI

        cmp [edx + ecx], byte 'd'  ; parse D
        jne .notD 
            mov [argType], dword 2  ; argType = 2
            inc dword [curFormat]
            jmp .finish
        .notD

        cmp [edx + ecx], byte '%'  ; parse %
        jne .notPer
            mov [argType], dword 3 ; argType = 3
            inc dword [curFormat]
            jmp .finish
        .notPer
        
        .finish


        ret

    ; this function writes to the buffer long long number form "numberUp" and "numberDown"

    convertToBuffer:
        mov [curBuffer], dword 0
        mov [sign], dword 0 
        cmp [argType], dword 2 
        jne .notNeg                      ; check number sign
            cmp [typeSize], dword 1              
            je .longCase
                mov eax, [numberDown]    ; short case = 32 bits
                shr eax, 31 
                cmp eax, 1
                jne .notNeg 
                    mov [sign], dword 1  ; sing = 1 <=>  '-'
                    mov eax, -1          ; assert eax = 2*32 - 1
                    mov [numberUp], eax

            jmp .overLongCase 
            .longCase 
                mov eax, [numberUp]     ; long case = 64 bits
                shr eax, 31
                cmp eax, 1              ; get first Bit
                jne .notNeg 
                    mov [sign], dword 1
            .overLongCase
        .notNeg
        cmp [sign], dword 1
        jne .notNeg2                      ; create positive number from negative
            not dword [numberDown]        ; ~numberDown
            not dword [numberUp]          ; ! numberUp
            add dword [numberDown], 1     ; numberDown += 1
            adc dword [numberUp], 0       ; numberUp += carry Flag
        .notNeg2
        ;;;;;;;;;;;;;;;; unsinged long long  
        .loopStart
            cmp [numberUp], dword 0              ; check if numberUp  == 0
            jne .letsWork 
                cmp [numberDown], dword 0       ; check if numberDown == 0
                jne .letsWork
                    jmp .loopEnd   ; jump if (NumberUp == 0 and NumberDown == 0)

            .letsWork  
            call mod10             ; get ((numberUp * 2**32) + numberDown) % 10
            add al, '0'
            mov ecx, [curBuffer]
            mov [buffer + ecx], al ; write digit 
            call div10             ; (numberUp_numberDown) /= 10
            
            inc dword [curBuffer]  ; curBuffer++;

            jmp .loopStart
        .loopEnd 
        call reverseBuffer         ; reverse string with digits

        ;;;;;;;;;;;;;;;;

        cmp [sign], dword 1
        jne .notMinus
            call shiftBuffer        ; shift number right 
            mov [buffer], byte '-'  ; set minus before number
            jmp .overNotMinus
        .notMinus
            mov eax, [flags]
            and eax, FLAG_PLUS
            cmp eax, 0
            je .notPlus
                call shiftBuffer      ; shift number right 
                mov [buffer], byte '+'  ;set plus before number
                jmp .overNotMinus
            .notPlus
            mov eax, [flags]
            and eax, FLAG_SPACE
            cmp eax, 0
            je .overNotMinus
                call shiftBuffer       ; shift number  right 
                mov [buffer], byte ' '  ;set space before number
        .overNotMinus
        ret


    ; divide long long, which is recorded in pair < NumberUp, NumberDown > by 10
    
    div10:

        mov eax, [numberUp]     ; eax = numberUp 
        xor edx, edx            ; edx = 0
        mov ecx, 10             ; ecx = 10
        div ecx                 ; eax - quotient, edx - remainder
        mov [numberUp], eax     ; numberUp = eax
        mov eax, [numberDown];  ; eax = numberDown
        div ecx                 ; /= 10
        mov [numberDown], eax  ; numberDown = eax

        ret

    mod10:
        mov eax, [numberUp]  ; eax = numberUp 
        xor edx, edx         ; edx = 0
        mov ecx, 10;         ; ecx = 10
        div ecx              ; eax - quotient, edx - remainder
        mov eax, [numberDown]; eax = numberDown
        div ecx              ; /= 10
        mov eax, edx         ; move quotient to eax
        ret
    
    reverseBuffer:
        push esi
        push edi  
        push ebp
        mov edi, [curBuffer]  ; edi = size   
        shr edi, 1            ; size /= 2
        xor ecx, ecx          ; ecx = 0;
        .loopStart
            cmp ecx, edi      ; i != mid
            je .loopEnd 

                mov esi, [curBuffer] ; esi = size;
                dec esi              ; esi = size - 1
                sub esi, ecx
                                    ; ecx = i
                                    ; esi = size - 1 - i; 
                mov al, [buffer + ecx]
                mov bl, [buffer + esi]
                mov [buffer + ecx], bl
                mov [buffer + esi], al  ; swap operations
                inc ecx                 ; i++
            jmp .loopStart 
        .loopEnd 
         
        pop ebp
        pop edi
        pop esi 
        ret

    ; shift all symbols in string buffer by one to the right

    shiftBuffer:
        mov ecx, [curBuffer]           ; ecx = buffer.size
        inc dword [curBuffer]          ; buffer.size++
        .loopStart
            mov al, [buffer + ecx - 1] ; buffer[ecx + 1] = buffer[ecx]
            mov [buffer + ecx], al
            dec ecx
            cmp ecx, 0                 ; if ecx == 0 break;
            jne .loopStart
        ret

    writeBuffer:
        push esi
        push edi
        xor ecx, ecx                   ; xor = 0

        mov edi, [output]              ; pointer to output
        .loopStart
            cmp ecx, [curBuffer]       ; ecx = curBuffer
            je .loopEnd
            mov al, [buffer + ecx]     ; output[curOutpu] = buffer[ecx]
            mov esi, [curOutput]
            mov [edi + esi], al

            inc dword [curOutput]      ; curOutput++
            inc ecx                    ; ecx++
            jmp .loopStart 
        .loopEnd 
         
        pop edi
        pop esi
        ret

    writeSpace:
        mov eax, [flags]
        and eax, FLAG_ZERO
        cmp eax, 0                     ; eax == FLAG_ZERO
        je .notZero
            mov al, '0'                ; we filled with '0'
            jmp .overNotZero
        .notZero
            mov al, ' '                ; filled with ' ' 
        .overNotZero

        .loopStart
            cmp [spaceSize], dword 0   ; while "spaceSize" > 0
            je .loopEnd 
            initOutput
            mov [edx + ecx], al        ; move [edx + ecx] = al 

            inc dword [curOutput]      ; curOutput++
            dec dword [spaceSize]      ; spaceSize--
            jmp .loopStart      
        .loopEnd 
    
        ret 

section .bss
        format    :  resd 1
        output    :  resd 1
        curFormat :  resd 1
        curOutput :  resd 1
        flags     :  resd 1
        width     :  resd 1
        typeSize  :  resd 1
        argType   :  resd 1  ; 1 = u ; 2 = (i|d); 3 = % ; 0 <=> Fail
        posBeforeParse: resd 1
        numberUp  :  resd 1
        numberDown:  resd 1
        shift     :  resd 1
        buffer    :  resb 25
        curBuffer :  resd 1
        sign      :  resd 1
        filler    :  resb 1
        spaceSize :  resd 1
