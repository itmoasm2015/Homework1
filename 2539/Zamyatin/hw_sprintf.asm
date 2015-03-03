global  hw_sprintf

section .text


FLAG_PLUS               equ     1 << 0         ; always show sign?
FLAG_SPACE              equ     1 << 1         ; space?
FLAG_MINUS              equ     1 << 2         ; show number right-padded? 
FLAG_ZERO               equ     1 << 3         ; show number zero-padded?
FLAG_LONG               equ     1 << 5         ; is number 64-bit?
FLAG_UNSIGNED           equ     1 << 4         ; is number unsigned?
FLAG_SIGN               equ     1 << 7         ; is number negative?




hw_sprintf:
        push            ebx
        push            esi
        push            edi
        push            ebp

        mov             ebx, [esp + 20]
        mov             [osp], ebx              ; out string pointer
        mov             esi, [esp + 24] ; format string pointer
        lea             ebx, [esp + 28] ; first argument pointer
        mov             [ap], ebx 
        

;__________________
;lexema A:
;|"%" + lexB + lexA
;| c  + lexA
lexA:
        cmp             byte [esi], 0
        jz              exit

        cmp             byte [esi], '%'
        jz              lexB

        mov             ebx, [osp]
        xor             eax, eax
        mov             al, [esi]
        mov             [ebx], al
        inc             ebx
        mov             [osp], ebx
        inc             esi
        jmp             lexA
;_________________
;lexema B(flags):
lexB:
        xor             edx, edx
        inc             esi
        push            esi
        cmp             byte [esi], '%'
        jnz             .loop
        add             esp, 4
        inc             esi
        mov             ebx, [osp]
        mov             edx, '%'
        mov             [ebx], dl
        inc             ebx
        mov             [osp], ebx
        jmp             lexA
        
.loop:
        cmp             byte [esi], '+'
        jnz             .skp_pls_flg
        or              edx, FLAG_PLUS
        inc             esi
        jmp             .loop

.skp_pls_flg:
        
        cmp             byte [esi], ' '
        jnz             .skp_spc_flg
        or              edx, FLAG_SPACE
        inc             esi
        jmp             .loop

.skp_spc_flg:

        cmp             byte [esi], '-'
        jnz             .skp_mns_flg
        or              edx, FLAG_MINUS
        inc             esi
        jmp             .loop

.skp_mns_flg:

        cmp             byte [esi], '0'
        jnz             .skp_zr_flg
        or              edx, FLAG_ZERO
        inc             esi
        jmp             .loop

.skp_zr_flg:

        call            get_number ; store into eax

        cmp             byte [esi], 'l'
        jnz             .skp_ll_flg
        inc             esi
        cmp             byte [esi], 'l'
        jnz             .bad_flags
        inc             esi
        or              edx, FLAG_LONG
        
.skp_ll_flg

        cmp             byte [esi], 'd'
        jnz             .skp_d_flg
        ; no or
        inc             esi
        jmp             .skp_i_flg

.skp_d_flg

        cmp             byte [esi], 'u'
        jnz             .skp_u_flg
        or              edx, FLAG_UNSIGNED
        inc             esi
        jmp             .skp_i_flg

.skp_u_flg

        cmp             byte [esi], 'i'
        jnz             .bad_flags
        ; no or like %d
        inc             esi

.skp_i_flg:

        shl             eax, 8
        or              edx, eax
        mov             ebx, [ap]
        mov             eax, [ebx]
        add             ebx, 4
        test            edx, FLAG_LONG
        jz              .no_ll
        mov             ebp, [ebx]
        add             ebx, 4
.no_ll: 
        mov             [ap], ebx
        call            write_number
        add             esp, 4
        jmp             lexA

.bad_flags:     
        mov             edx, [osp]
        mov             ebx, '%'
        mov             [edx], bl
        inc             edx
        mov             [osp], edx
        pop             esi
        jmp             lexA
;_________________

exit:
        mov             edx, [osp]
        mov             ebx, 0
        mov             [edx], ebx

        pop             ebp
        pop             edi
        pop             esi
        pop             ebx

        ret


;________________________________________
; number from string
; esi - pointer to string
; answer in eax
get_number:
        push            edx
        xor             eax, eax
.loop:
        cmp             byte [esi], '0'
        jb              .complete
        cmp             byte [esi], '9'
        ja              .complete
        mov             edx, 10
        mul             edx
        xor             edx, edx
        mov             dl, [esi]
        sub             edx, '0'
        add             eax, edx
        inc             esi
        jmp             .loop
.complete:
        pop             edx
        ret 

;________________________________________
; arg in eax print into osp
; if long long highest part in ebp
; in edx flags
; don't save nubmer in eax
; edx: flags //(0-pls_flg) (1-spc_flg) (2-mns_flg) (3-zr_flg) (4-6 type) (7 sign) (8-31 number)
; type 0: %d
; type 1: %u
; type 2: %lld
; type 3: %llu

write_number:
        ;_______need to be removed________
        ;test   edx, FLAG_UNSIGNED
        ;jz             .not_u
        ;and    dl, (1 << 8) - 1 - 1 - 2
        ;.not_u
        ;_________________________________

        test            edx, FLAG_LONG
        jz              .short_number
        push            ecx
        push            ebx
        push            edx
        mov             ecx, 0
        call            handle_ll ; eax - lower, ebp - highest
        jmp             .handle_sign

.short_number:  
        test            edx, FLAG_UNSIGNED
        jnz             .sign_is_pls
        
        cmp             eax, 0
        jge             .sign_is_pls
        or              edx, FLAG_SIGN|FLAG_PLUS ; set sign flag and take abs value
        neg             eax

.sign_is_pls                            

        push            ecx
        push            ebx
        push            edx

        mov             ebx, 10
        mov             ecx, 0
.divide:
        mov             edx, 0
        div             ebx
        add             dl, '0'
        push            edx
        inc             ecx
        cmp             eax, 0
        jnz             .divide

        mov             edx, [esp + ecx * 4] ; comeback edx value(flags)

.handle_sign:   
        test            edx, FLAG_SIGN ; check sign of argument
        jz              .sign_is_plls
        inc             ecx
        push            '-'
        jmp             .no_spc_flg
.sign_is_plls:
        test            edx, FLAG_PLUS ; check plus flag
        jz              .no_pls_flg
        inc             ecx
        push            '+'
        jmp             .no_spc_flg
.no_pls_flg:
        test            edx, FLAG_SPACE ; check space flag
        jz              .no_spc_flg
        inc             ecx
        push            ' '
.no_spc_flg:
        
        test            edx, FLAG_MINUS
        jnz             .let_dump_string
        test            edx, FLAG_ZERO
        jz              .no_zr_flg

        mov             ebx, edx
        shr             ebx, 8
        sub             ebx, ecx

        test            edx, FLAG_PLUS | FLAG_SPACE
        jz              .push_zr_loop
        pop             ebp ; sign in ebp

.push_zr_loop:
        cmp             ebx, 0
        jle             .finish_zr
        push            '0'
        inc             ecx
        dec             ebx
        jmp             .push_zr_loop
.finish_zr:
        test            edx, FLAG_PLUS | FLAG_SPACE
        jz              .let_dump_string
        push            ebp
        jmp             .let_dump_string
.no_zr_flg:     
        mov             ebx, edx
        shr             ebx, 8
        sub             ebx, ecx
.push_spc_loop:
        cmp             ebx, 0
        jle             .finish_spc
        push            ' '
        inc             ecx
        dec             ebx
        jmp             .push_spc_loop
.finish_spc:
.let_dump_string:
        shr             edx, 8
        mov             ebx, [osp]
.loop
        pop             eax
        mov             [ebx], al
        inc             ebx
        dec             edx
        dec             ecx
        jnz             .loop
.push_spc_loop1:
        cmp             edx, 0
        jle             .finish_spc1
        mov             eax, ' '
        mov             [ebx], al
        inc             ebx
        dec             edx
        jmp             .push_spc_loop1
.finish_spc1:
        mov             [osp], ebx
        pop             edx 
        pop             ebx
        pop             ecx
        ret
;________________________________________
        
;puts long number
;in eax lowest part, in ebp highest part
;in edx flags
;don't save eax and ebp
;increase ecx
;don't save edi, ebx
handle_ll:
        test            edx, FLAG_UNSIGNED
        jnz             .sign_is_pls

        cmp             ebp, 0
        jge             .sign_is_pls
        xor             eax, 4294967295
        xor             ebp, 4294967295
        add             eax, 1
        adc             ebp, 0
        or              edx, FLAG_SIGN|FLAG_PLUS ; set sign flag and take abs value
.sign_is_pls:
        mov             [tmp], edx
        pop             edx
        mov             [return_adress], edx

.divide:
        mov             edx, 0
        mov             edi, 10
        div             edi
        push            edx
        push            eax

        mov             eax, ebp
        mov             edx, 0
        div             edi
        mov             ebx, edx
        mov             edi, 6
        mul             edi
        push            eax
        mov             eax, ebx
        mul             edi
        mov             edi, 10
        mov             edx, 0
        div             edi
        push            edx
        push            eax
        mov             eax, ebp
        mov             edi, 429496729 ; 429496729 = [2^32 / 10]
        mul             edi
        
        mov             edi, 0

        pop             ebx
        add             eax, ebx
        adc             edx, 0
        
        pop             ebx
        add             edi, ebx


        pop             ebx
        add             eax, ebx
        adc             edx, 0
                
        pop             ebx
        add             eax, ebx
        adc             edx, 0

        pop             ebx
        add             edi, ebx
        
        mov             ebp, edx
        cmp             edi, 10
        jl              .no_sub
        sub             edi, 10
        inc             eax
.no_sub:
        add             edi, '0'
        push            edi

        inc             ecx
        mov             edi, eax
        or              edi, ebp
        cmp             edi, 0
        jnz             .divide
        mov             edx, [return_adress]
        push            edx
        mov             edx, [tmp]
        ret

section .bss
        osp:            resd 1
        fsp:            resd 1
        ap:             resd 1
        tmp:            resd 1
        return_adress:  resd 1
        tmp1:           resd 1
