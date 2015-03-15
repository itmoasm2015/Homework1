section .data
    string1 db  "Hello World!",10,0

section .text
    global _start

    _start:
        ; calculate the length of string
        mov     edi, dword string1
        mov     ecx, dword -1
        xor     al,al
        cld
        repnz scasb

        ; place the length of the string in RDX
        mov     edx, dword -2
        sub     edx, ecx

        ; print the string using write() system call 
        mov     esi, dword string1
        push    0x1
        pop     eax
        mov     edi,eax

        ; exit from the application here
        xor     edi,edi
        push    0x3c
        pop     eax
        syscall
