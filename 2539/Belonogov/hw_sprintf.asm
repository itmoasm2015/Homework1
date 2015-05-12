global hw_atoi
global hw_sprintf

%define FLAG_PLUS 1
%define FLAG_SPACE 2
%define FLAG_MINUS 4
%define FLAG_ZERO 8

%macro initFormat 0
    mov ecx, [curFormat]
    mov edx, [format]
%endmacro

%macro initOutput 0
    mov ecx, [curOutput]
    mov edx, [output]
%endmacro

section .text

    hw_atoi:
        mov eax, esp
        push ebp 
        push edi
        mov ebp, eax

        mov edi, [ebp + 4]
        mov al, 'a' 
        mov [edi], al
        mov al, 'b' 
        mov [edi + 1], al
       

        pop edi 
        pop ebp
        ret


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
                    xor eax, eax                        ; eax = 0
                    mov [numberUp], eax                 ; clear numberDown
                    mov [numberDown], eax               ; clear numberUp
                    ;;; TODO case with %                      
                    cmp [width]



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
        xor eax, eax         ; eax = 0
        mov [flags], eax
        .loopStart
            initFormat
            ;;;;;;;;;;;;;;;;;;;+++++++++++++++
            cmp [edx + ecx], byte '+'
            jne .notPlus                  
                mov eax, FLAG_PLUS 
                or  [flags], eax 
                inc dword [curFormat]; 
                jmp .loopStart
            .notPlus
            ;;;;;;;;;;;;;;;;;;;    
            cmp [edx + ecx], byte ' '
            jne .notSpace
                mov eax, FLAG_SPACE
                or  [flags], eax 
                inc dword [curFormat]; 
                jmp .loopStart
            .notSpace
            ;;;;;;;;;;;;;;;;;;; -------------
            cmp [edx + ecx], byte '-'
            jne .notMinus
                mov eax, FLAG_MINUS
                or  [flags], eax 
                inc dword [curFormat]; 
                jmp .loopStart
            .notMinus

            cmp [edx + ecx], byte '0'
            jne .notZero
                mov eax, FLAG_ZERO
                or  [flags], eax 
                inc dword [curFormat]; 
                jmp .loopStart
            .notZero

        ret
        
    parseWidth:
        push esi
        push edi 
        xor eax, eax
        mov [width], eax 

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
            

        .loopEnd

        pop edi
        pop esi
        ret

    parseSize:
        xor eax, eax
        mov [typeSize], eax
       
        initFormat
        cmp [edx + ecx], byte 'l'
        jne .notLong
            cmp [edx + ecx + 1], byte 'l' 
            jne .notLong
                mov eax, 1    
                mov [typeSize], eax


        .notLong

        ret

    parseType:
        initFormat
        xor eax, eax
        mov [argType], eax 
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


