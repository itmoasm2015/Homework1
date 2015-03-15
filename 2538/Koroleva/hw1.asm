%define FLAG_PLUS 1		;флажок "+"
%define FLAG_SPACE 2		;флажок " "
%define FLAG_MINUS 4		;флажок "-"
%define FLAG_ZERO 8		;флажок "0"
%define FLAG_LONG_LONG 16	;поставить 1, если long long, и 0 в противном случае
%define FLAG_SIGN 32		;поставить 1, если число отрицательное и, 0 в противном случае


section .text
global hw_sprintf


;void* write_unsigned(void* args, int width, int flags)
;Функция получает на вход указатель на текущий аргумент, ширину и флаги.
;Возвращает указатель на следующий аргумент.
write_unsigned:
	push ebp
	mov ebp, esp

	mov ecx, edi  ;сохраним указатель на строку, в которую выводим 
	mov edi, ebp  ;здесь будем хранить указатель на конец числа в смсысле строки
	sub esp, 24   ;выделяем для строки числа память на стеке, 24 байта 
	push esi
	push ecx

	mov ebx, [ebp + 16] ;флажки
	mov esi, [ebp + 8] ;указатель на начало аргументов
	mov ecx, 10   ;база системы счисления

	test ebx, FLAG_LONG_LONG ;длинные и не очень числа обрабатываем по-разному 
	jnz .long

	mov eax, [esi]		;если короткое, то достаточно eax
	add esi, 4

.loop				;делим на 10, остаток в виде символа 	
	mov edx, 0		;	записываем на стек, двинаем указатель на конец - edi 
	div ecx			
	add edx, '0'
	dec edi
	mov byte[edi], dl
	cmp eax, 0
	jne .loop
	jmp .write

.long
	mov eax, [esi]		;младшие биты числа
	add esi, 4          
	mov edx, [esi]		;старшие биты числа
	add esi, 4
	push esi		;будем портить, поэтому нужно запомнить 

.long_loop
	cmp edx, 0		;если число в какой-то момент превратилось в короткое, то продолжим его считать как короткое
	jne .continue
	pop esi			
	jmp .loop
	
.continue
	push eax           
	mov eax, edx		;сначала поделим старший разряд
	mov edx, 0
	div ecx
	mov esi, eax		;запомним результат, а остаток оставим в edx
	pop eax			;поделим младший разряд с остатком от предыдущего деления в edx
	div ecx	
				;теперь результат в eax, а остаток в edx. Осталось перевести его в символ, 
				;	записать, а в edx вернуть результат от первого деления
	add edx, '0'
	dec edi
	mov byte[edi], dl
	mov edx, esi
	jmp .long_loop		
	
.write				;теперь нужно записать строчку, получившуюся на стеке, учитывая формат
	mov eax, edi		;указатель на конец числа(в смысле строки) теперь в eax
	pop edi			;edi снова указывает на текущий символ строки out 

	mov ecx, [ebp + 12]	;в ecx поместим ширину 
	mov edx, ebp
	sub edx, eax		;а в edx - длину строки, описывающей число 

	cmp ecx, edx		;если ширина не больше текущей длины, то опустим всякие 
				;	дополнения до ширины и сразу пойдем писать число 
	jle .flag_sign

	sub ecx, edx		;а если нет, то теперь в ecx - количество символов, которые нужно дописать 
	
	test ebx, FLAG_PLUS	;если нужно обязательно вывести знак числа или пробел перед ним, то ecx уменьшается на 1 
	jnz .less_width
	test ebx, FLAG_SIGN
	jnz .less_width
	test ebx, FLAG_SPACE
	jnz .less_width
        jmp .flag_minus
	
.less_width
	dec ecx

.flag_minus			;если есть флаг "-" или "0", то не нужно выводить дополнительные пробелы перед числом 
	test ebx, FLAG_MINUS
	jnz .flag_sign

	test ebx, FLAG_ZERO
	jnz .flag_sign


.prev_loop			;а иначе - давайте их выведем 
	mov dl, ' '
	mov byte[edi], dl
	inc edi
	dec ecx
	cmp ecx, 0
	jg .prev_loop

.flag_sign			;следующие три метки записывают знак числа или пробел, если они нужны 
	test ebx, FLAG_SIGN
	jz .flag_plus
	mov dl, '-'
	mov byte[edi], dl
	inc edi
	jmp .flag_zero

.flag_plus
	test ebx, FLAG_PLUS
	jz .flag_space
	mov dl, '+'
	mov byte[edi], dl
	inc edi
	jmp .flag_zero
.flag_space
	test ebx, FLAG_SPACE
	jz .flag_zero
	mov dl, ' '
	mov byte[edi], dl
	inc edi

.flag_zero 			;если есть флаг "-", то мы игнорируем флаг "0", иначе дополняем нулями(prev_loop_zero)
	test ebx, FLAG_MINUS
	jnz .write_loop
	test ebx, FLAG_ZERO
	jz .write_loop

.prev_loop_zero
	mov dl, '0'
	mov byte[edi], dl
	inc edi
	dec ecx
	cmp ecx, 0
	jg .prev_loop_zero
	jmp .write_loop
	
.write_loop			;теперь, наконец-то, запишем в out наше число!
	mov dl, byte[eax]
	mov byte[edi], dl
	inc edi
	inc eax
	cmp eax, ebp
	jne .write_loop

	test ebx, FLAG_MINUS	;если был флаг "-", то нужно дополнить его до ширины пробелами(minus_loop) 
	jz .ret
.minus_loop
	mov dl, ' '
	mov byte[edi], dl
	inc edi
	dec ecx
	cmp ecx, 0
	jg .minus_loop

.ret
	mov eax, esi		;возвращаемое значение сохраняется в eax 
	pop esi 

	mov esp, ebp
	pop ebp
	ret


;void* write_signed(void* args, int width, int flags)
;Функция принимает указатель на аргументы, ширину и флаги
;Исходя из флагов переписывает текущий аргумент в строку out и возвращает указатель на следующий аргумент
write_signed:
	push ebp
	mov ebp, esp

	mov ebx, [ebp + 16]		;здесь будут жить флажки
	mov ecx, [ebp + 8]		;а здесь указатель на аргументы

	test ebx, FLAG_LONG_LONG	;если чиселко не длинное, то мы его предварительно обработаем 
	jnz .long

	mov eax, [ecx]
	bt eax, 31
	jnc .calling
	mov edx, ~0			;а именно - если оно отрицательное - забьем в edx кучу единиц
	jmp .set_minus			;	и представим, что оно длинное

.long
	mov eax, [ecx]
	add ecx, 4
	mov edx, [ecx]
	sub ecx, 4
	bt edx, 31
	jnc .calling

.set_minus
	not edx				;берем модуль числа
	not eax
	add eax, 1
	adc edx, 0
	or ebx, FLAG_SIGN		;говорим, что у нас отрицательный знак

	mov [ecx], eax			;подставлям получившееся положительное число вместо аргумента, который был
	test ebx, FLAG_LONG_LONG
	jz .calling

	add ecx, 4
	mov [ecx], edx	
	sub ecx, 4

.calling
	mov edx, [ebp + 12]
	push ebx
	push edx
	push ecx
	call write_unsigned		;и сделав вид, что оно беззнаковое, вызовем эту функцию 
	pop ecx
	pop edx
	pop ebx
.ret
	pop ebp
	ret

;int string_to_int();
;Читает символы являющиеся цифрами с текущего места строчки формата(esi) 
;и переводит их в int
;Результат записан в eax

string_to_int:
	push ebp
	mov ebp, esp
	mov eax, 0	;инициализация

.loop
	cmp cl, '0'	;если символ не цифра - возвращаемся
	jl .ret
	cmp cl, '9'
	jg .ret

	mov ebx, 10	;перевод строки в число
	mul ebx
	sub cl, '0'
	add al, cl	

	mov cl, byte[esi]	;двигаем текущий элемент
	inc esi

	jmp .loop

.ret
	pop ebp
	ret	

;void write_to_out()
;эта функция выводит все символы от указателя eax, до esi
write_to_out:
	push ebp
	mov ebp, esp
.loop
	mov cl, byte[eax]
	mov byte[edi], cl
	inc eax
	inc edi

	cmp eax, esi		;если еще не дошли до конца - продолжим
	jne .loop

	pop ebp
	ret

; void hw_sprintf(char* out, char* format, ...)
;out - строчка, в которую нужно записать
;format - строчка формата
;остальное - аргументы, подставляемые в формат

hw_sprintf:
	push ebp
	mov ebp, esp

	push esi
	push edi
	push ebx

	mov edi, [ebp + 8]	;указатель на текущее место, куда мы пишем в строке out
	mov esi, [ebp + 12]	;указатель на текущий символ формата
	lea edx, [ebp + 16]	;указатель на текущий аргумент
	mov eax, esi		;будет указывать на то место в строке формата, откуда мы начали разбирать выражение после %,
	        		;	если формат не корректный, то с этого места до текущего мы просто выведем все 

.loop
	mov ebx, 0		;регистр ebx будет использоваться для флажков
	mov cl, byte[esi]	;в регистр ecx будут записываться какие-то текущие 
				;вычисления или значения, которые надо где-то хранить 

	cmp cl, 0		;проверка на символ конца строки
	je .ret
	inc esi			
	
	push eax		;eax в дальнейшем используется для вычисления ширины, 
				;поэтому нужно сохранить его значение

	cmp cl, '%'		;проверка, не началось ли описание вывода какого-то аргумента
	jne .no_format

.format
	mov cl, byte[esi]
	inc esi

	cmp cl, '+'		;проверки на флаги. Если повстречался флаг,	
	jne .space		;	снова идем в начало цикла определения флагов

	or ebx, FLAG_PLUS
	jmp .format

.space
	cmp cl, ' '
	jne .minus
	or ebx, FLAG_SPACE
	jmp .format

.minus 
	cmp cl, '-'
	jne .zero
	or ebx, FLAG_MINUS
	jmp .format

.zero
	cmp cl, '0'
	jne .width
	or ebx, FLAG_ZERO
	jmp .format

.width
	push ebx		;эти регистры портятся при вызове вычисления ширины, поэтому надо их сохранить
	push edx
	call string_to_int	;функция вычисления ширины
	pop edx
	pop ebx

.size				;проверка размера
	cmp cl, 'l'		
	jne .type

	mov cl, byte[esi]
	inc esi
	cmp cl, 'l'
	jne .no_format

	or ebx, FLAG_LONG_LONG
	mov cl, byte[esi]
	inc esi

.type				;проверка типа
	cmp cl, 'i'	
	je .signed

	cmp cl, 'd'
	je .signed

	cmp cl, 'u'
	je .unsigned

	cmp cl, '%'
	je .percent
	jmp .no_format	
	
.signed
	push ebx		;передаем аргументы в функцию
	push eax
	push edx
	call write_signed
	pop edx
	mov edx, eax		;присваиваем возвращаемое значение куда надо
	pop eax
	pop ebx

	pop eax			;восстанавливаем указатель на строку формата
	mov eax, esi		;передвигаем его на нужное место

	jmp .loop

.unsigned
	push ebx		;передаем аргументы в функцию
	push eax
	push edx
	call write_unsigned	
	pop edx
	mov edx, eax		;присваиваем возвращаемое значение куда надо
	pop eax
	pop ebx
	

	pop eax 		;восстанавливаем указатель на строку формата
	mov eax, esi		;передвигаем его на нужное место
	jmp .loop

.percent
	mov byte[edi], cl	;поскольку мы попали сюда, значит в cl был %. Так выведем же его!
	inc edi
	pop eax
	mov eax, esi		;передвигаем указатель на текущее место

	jmp .loop	

.no_format
	pop eax			
	call write_to_out
	jmp .loop
	
.ret
	mov byte[edi], cl	;записываем символ конца строки
	inc edi

	pop ebx
	pop edi
	pop esi
	pop ebp
	ret




