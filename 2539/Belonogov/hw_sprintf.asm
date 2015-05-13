global hw_atoi
global hw_sprintf

%define FLAG_PLUS  1
%define FLAG_SPACE 2
%define FLAG_MINUS 4
%define FLAG_ZERO  8

%macro initFormat 0
    mov ecx, [curFormat]
    mov edx, [format]
%endmacro

%macro initOutput 0
    mov ecx, [curOutput]
    mov edx, [output]
%endmacro


section .text

    hw_sprintf:
        mov eax, esp
        push edi
        push esi
        push ebp
        push ebx
        mov ebp, eax
        mov eax, [ebp + 4]       ;  first argument
        mov [output], eax
        mov eax, [ebp + 8]       ; second argument
        mov [format], eax
        mov [curFormat], dword 0 ; curFormat = 0;
        mov [curOutput], dword 0 ; curOutput = 0;
        mov [shift],     dword 12; 
        
        .mainLoop
            ;mov eax, [format] 
            ;mov ecx, [curFormat];
            initFormat
            cmp [edx + ecx], dword 0   ; if curFromat == /0  => end of string
            je .mainLoopEnd            ; go to finish
            cmp [edx + ecx], byte '%'  ;
            je .parseToken 
                mov al, [edx + ecx]    ; al = format[curFormat]
                initOutput
                mov [edx + ecx], al    ; write one symbol from "format" to "output"
               
                inc dword [curFormat]  ; curFromat++
                inc dword [curOutput]  ; curOutput++ 


            jmp .overParseToken
            .parseToken
                mov eax, [curFormat]
                mov [posBeforeParse], eax 

                inc dword [curFormat]
                call parseFlags        ; variable "flags" has been initialized 
                call parseWidth        ; variable "width" has been initialized 
                    
                call parseSize         ; variable "size" has been initialized 
                call parseType         ; variable "argType" has been initialized 

                
                cmp [argType], dword 0
                jne .ok
                    .loopStart1                        ; if something wrong, when let's copy wrong substring
                                                       ; to output string
                        mov eax, [posBeforeParse]
                        cmp [curFormat], eax
                        je .loopEnd1
                            mov ecx, [posBeforeParse]
                            mov edx, [format]
                            mov al, [edx + ecx]
                            initOutput
                            mov [edx + ecx], al         ; write to output string
                        inc dword [curOutput]
                        inc dword [posBeforeParse]
                        jmp .loopStart1
                    .loopEnd1
                jmp .overOk
                .ok
                    ;;; TODO case with %                      
                    cmp [argType], dword 3
                    jne .normCase
                        initOutput
                        mov [edx + ecx], byte '%'
                        inc dword [curOutput]
                        jmp .overParseToken
                    .normCase

                    mov [numberUp],   dword 0            ; clear numberDown
                    mov [numberDown], dword 0            ; clear numberUp
                    mov ecx, [shift]
                    mov eax, [ebp + ecx] 
                    mov [numberDown], eax
                    add [shift], dword 4 

                    cmp [typeSize], dword 1
                    jne .notCaseLL
                        mov ecx, [shift]
                        mov eax, [ebp + ecx] 
                        mov [numberUp], eax
                        add [shift], dword 4 
                    .notCaseLL
                    call convertToBuffer   
                         
                    mov eax, [width]
                    cmp eax, [curBuffer]                         
                    jle .emptySpace
                        mov eax, [width]
                        sub eax, [curBuffer]
                        mov [spaceSize], eax
                    jmp .overEmptySpace
                    .emptySpace 
                        mov [spaceSize], dword 0 
                    .overEmptySpace
                    mov eax, [flags]
                    and eax, FLAG_MINUS
                    cmp eax, 0
                    je .rightOrder
                        call writeBuffer
                        call writeSpace
                        jmp .overRightOrder
                    .rightOrder
                        call writeSpace
                        call writeBuffer
                    .overRightOrder
                .overOk
            .overParseToken 
        
        
        jmp .mainLoop 
        .mainLoopEnd 


        pop ebx
        pop ebp
        pop esi
        pop edi
        ret



    parseFlags:
        mov [flags], dword 0
        .loopStart
            initFormat
            ;;;;;;;;;;;;;;;;;;;+++++++++++++++
            cmp [edx + ecx], byte '+'
            jne .notPlus                  
                or  [flags], dword FLAG_PLUS 
                inc dword [curFormat]; 
                jmp .loopStart
            .notPlus
            ;;;;;;;;;;;;;;;;;;;    
            cmp [edx + ecx], byte ' '
            jne .notSpace
                or  [flags], dword FLAG_SPACE 
                inc dword [curFormat]; 
                jmp .loopStart
            .notSpace
            ;;;;;;;;;;;;;;;;;;; -------------
            cmp [edx + ecx], byte '-'
            jne .notMinus
                or  [flags], dword FLAG_MINUS
                inc dword [curFormat]; 
                jmp .loopStart
            .notMinus

            cmp [edx + ecx], byte '0'
            jne .notZero
                or  [flags], dword FLAG_ZERO
                inc dword [curFormat]; 
                jmp .loopStart
            .notZero

        mov eax, [flags]
        and eax, FLAG_MINUS
        cmp eax, 0
        je .finish
            mov eax, [flags]
            and eax, FLAG_ZERO
            cmp eax, 0
            je .finish
                xor [flags], dword FLAG_ZERO

        .finish


        ret
        
    parseWidth:
        push esi
        push edi 
        mov [width], dword 0

        .loopStart
            initFormat
            cmp [edx + ecx], byte '0'
            jb .loopEnd
            cmp [edx + ecx], byte '9'
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

    parseSize:
        mov [typeSize], dword 0
       
        initFormat
        cmp [edx + ecx], byte 'l'
        jne .notLong
            cmp [edx + ecx + 1], byte 'l' 
            jne .notLong
                mov [typeSize], dword 1
                add dword [curFormat], 2

        .notLong

        ret

    parseType:
        initFormat
        mov [argType], dword 0
        cmp [edx + ecx], byte 'u'  ; parse U 
        jne .notU 
            mov eax, 1
            mov [argType], eax
            inc dword [curFormat]
            jmp .finish
        .notU
        
        cmp [edx + ecx], byte 'i'  ; parse I
        jne .notI 
            mov eax, 2
            mov [argType], eax
            inc dword [curFormat]
            jmp .finish
        .notI

        cmp [edx + ecx], byte 'd'  ; parse D
        jne .notD 
            mov eax, 2
            mov [argType], eax
            inc dword [curFormat]
            jmp .finish
        .notD

        cmp [edx + ecx], byte '%'  ; parse %
        jne .notPer
            mov eax, 3
            mov [argType], eax
            inc dword [curFormat]
            jmp .finish
        .notPer
        
        .finish


        ret


    convertToBuffer:
        mov [curBuffer], dword 0
        mov [sign], dword 0 
        cmp [argType], dword 2 
        jne .notNeg  
            cmp [typeSize], dword 1              
            je .longCase
                mov eax, [numberDown]    ; short case = 32 bits
                shr eax, 31 
                cmp eax, 1
                jne .notNeg 
                    mov [sign], dword 1
                    mov eax, 1
                    shl eax, 31
                    sar eax, 31         ; assert eax = 2*32 - 1
                    mov [numberUp], eax

            jmp .overLongCase 
            .longCase 
                mov eax, [numberUp]     ; long case = 64 bits
                shr eax, 31
                cmp eax, 1
                jne .notNeg 
                    mov [sign], dword 1
            .overLongCase
        .notNeg
        cmp [sign], dword 1
        jne .notNeg2
            not dword [numberDown] 
            not dword [numberUp] 
            add dword [numberDown], 1
            adc dword [numberUp], 0
        .notNeg2
        ;;;;;;;;;;;;;;;; unsinged long long  
        .loopStart
            cmp [numberUp], dword 0 
            jne .letsWork 
                cmp [numberDown], dword 0
                jne .letsWork
                    jmp .loopEnd   ; jump if (NumberUp == 0 and NumberDown == 0)

            .letsWork  
            call mod10 
            add al, '0'
            mov ecx, [curBuffer]
            mov [buffer + ecx], al
            call div10  
            
            inc dword [curBuffer]

            jmp .loopStart
        .loopEnd 
        call reverseBuffer

        ;;;;;;;;;;;;;;;;

        cmp [sign], dword 1
        jne .notMinus
            call shiftBuffer
            mov [buffer], byte '-'
            jmp .overNotMinus
        .notMinus
            mov eax, [flags]
            and eax, FLAG_PLUS
            cmp eax, 0
            je .notPlus
                call shiftBuffer
                mov [buffer], byte '+' 
                jmp .overNotMinus
            .notPlus
            mov eax, [flags]
            and eax, FLAG_SPACE
            cmp eax, 0
            je .overNotMinus
                call shiftBuffer
                mov [buffer], byte ' '
        .overNotMinus
        ret


    ; divide long long, which is recorded in pair < NumberUp, NumberDown > by 10
    
    div10:

        mov eax, [numberUp]    
        xor edx, edx 
        mov ecx, 10
        div ecx                 ; eax - quotient, edx - remainder
        mov [numberUp], eax 
        mov eax, [numberDown];
        div ecx                 ; /= 10
        mov [numberDown], eax

        ret

    mod10:
        mov eax, [numberUp]    
        xor edx, edx 
        mov ecx, 10;
        div ecx              ; eax - quotient, edx - remainder
        mov eax, [numberDown];
        div ecx 
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
            cmp ecx, edi
            je .loopEnd 

                mov esi, [curBuffer] 
                dec esi
                sub esi, ecx
                                    ; ecx = i
                                    ; esi = size - 1 - i; 
                mov al, [buffer + ecx]
                mov bl, [buffer + esi]
                mov [buffer + ecx], bl
                mov [buffer + esi], al  ; swap operation
                inc ecx
            jmp .loopStart 
        .loopEnd 
         
        pop ebp
        pop edi
        pop esi 
        ret
    shiftBuffer:
        mov ecx, [curBuffer] 
        inc dword [curBuffer]
        .loopStart
            mov al, [buffer + ecx - 1]
            mov [buffer + ecx], al
            dec ecx
            cmp ecx, 0
            jne .loopStart
        ret
    writeBuffer:
        push esi
        push edi
        xor ecx, ecx

        mov edi, [output]
        .loopStart
            cmp ecx, [curBuffer]
            je .loopEnd
            mov al, [buffer + ecx]
            mov esi, [curOutput]
            mov [edi + esi], al

            inc dword [curOutput]
            inc ecx
            jmp .loopStart 
        .loopEnd 
         
        pop edi
        pop esi
        ret
    writeSpace:
        mov eax, [flags]
        and eax, FLAG_ZERO
        cmp eax, 0
        je .notZero
            mov al, '0'
            jmp .overNotZero
        .notZero
            mov al, ' '
        .overNotZero

        .loopStart
            cmp [spaceSize], dword 0 
            je .loopEnd 
            initOutput
            mov [edx + ecx], al

            inc dword [curOutput] 
            dec dword [spaceSize]
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
