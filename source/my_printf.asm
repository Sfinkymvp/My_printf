section .data

digits              db "0123456789ABCDEF"

section .bss

buffer              resb BUFFER_SIZE


section .text
    global my_printf

BUFFER_SIZE         equ 128
STDOUT_FD           equ 1


my_printf:
    pop r15                             ; Сохраняем адрес возврата

    push    r9                          ; 6-й аргумент
    push    r8                          ; 5-й аргумент
    push    rcx                         ; 4-й аргумент
    push    rdx                         ; 3-й аргумент
    push    rsi                         ; 2-й аргумент
    push    rdi                         ; 1-й аргумент (Форматная строка)
           
    sub     rsp, 8

    call    my_printf_logic

    add     rsp, 56
    push    r15                         ; Кладем обратно адрес возврата

    ret


; -----------------------------------------------------------------------------
; Procedure: my_printf_logic
; -----------------------------------------------------------------------------
; Описание:
;       Осуществляет форматный вывод строки в стандартный поток вывода
; Входные параметры:
;       [bp + 24] (Ptr)   - Указатель на форматную строку
;       [bp + 24 + 8 * i] - Данные для i-го спецификатора
; Выходные параметры:
;       Нет
; Портящиеся регистры:
;       callee-caller
; -----------------------------------------------------------------------------
my_printf_logic:
; --- Start prologue ---
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    r12
    push    r13
; --- End prologue --- 

    mov     rbx, rbp        
    add     rbx, 24

    mov     r12, [rbx]                  ; Кладем адрес форматной строки
    add     rbx, 8

    mov     r13, buffer                 ; Кладем адрес буфера

    xor     ecx, ecx
    xor     edx, edx 

.next_loop:
    cmp     rdx, BUFFER_SIZE
    jb      .skip_print

    push    rbx
    push    rcx
    push    rdx

    mov     rdi, r13
    mov     rsi, rdx
    call    print_buffer

    pop     rdx
    pop     rcx
    pop     rbx

    xor     edx, edx

.skip_print:
    cmp     byte [r12 + rcx], 0x00
    je      .done

    cmp     byte [r12 + rcx], '\'
    je      .escape_handler

    cmp     byte [r12 + rcx], '%'
    je      .spec_handler

    mov     r8b, [r12 + rcx]
    mov     byte [r13 + rdx], r8b

    inc     rcx
    inc     rdx
    jmp     .next_loop

.spec_handler:
    inc     rcx                         ; Переходим к следующему символу в формате

    cmp     byte [r12 + rcx], 'c'     
    je      .char_handler               

    cmp     byte [r12 + rcx], 'x'       
    je      .hex_handler

.char_handler:
    xor     eax, eax

    movzx   r8, byte [rbx]             ; Получаем символ
    add     rbx, 8

    mov     byte [r13 + rdx], r8b       ; Кладем в буфер символ
    inc     rcx
    inc     rdx
    jmp      .continue

.hex_handler:
    xor     eax, eax

    mov     r8, [rbx]                   ; Получаем число
    add     rbx, 8

    push    rcx

    mov     rdi, r8
    mov     rsi, 16                     ; Указываем систему счисления для записи числа
    mov     rcx, rdx
    mov     rdx, buffer

    sub     rsp, 8

    call    itoa
    add     rsp, 8

    pop     rcx

    inc     rcx
    mov     rdx, rax

    jmp     .continue

.escape_handler:
    inc rcx

    cmp    byte [r12 + rcx], 'n'
    je      .line_feed

.line_feed:
    mov     byte [r13 + rdx], 10

    inc rcx
    inc rdx

    jmp .continue

.continue:
    jmp     .next_loop

.done:
    mov     byte [r13 + rdx], 0         ; Заканчиваем строку ноль-терминатором
    inc rdx                             ; Учитываем ноль-терминатор в длине строки

    push    rdx

    mov     rdi, r13
    mov     rsi, rdx

    call print_buffer                   ; Выводим содержимое буфера в стандартный поток вывода

    pop     rdx

; --- Start epilogue --- 
    pop     r13
    pop     r12
    pop     rbx

    pop     rbp
; --- End epilogue --- 

    ret


; -----------------------------------------------------------------------------
; Procedure: print_buffer
; -----------------------------------------------------------------------------
; Описание:
;       Выводит содержимое буфера в стандартный поток вывода
; Входные параметры:
;       rdi - Указатель на буфер
;       rsi - Количество элементов в буфере
; Выходные параметры:
;       Нет
; Портящиеся регистры:
;       callee-caller
; -----------------------------------------------------------------------------
print_buffer:
    mov     rax, 1
    mov     rdx, rsi
    mov     rsi, rdi
    mov     rdi, STDOUT_FD

    syscall

    ret


; -----------------------------------------------------------------------------
; Procedure: itoa
; -----------------------------------------------------------------------------
; Описание:
;       Осуществляет запись числа в буфер в необходимой системе счисления
; Входные параметры:
;       rdi - Число
;       rsi - Основание системы счисления (2, 8, 10, 16)
;       rdx - Указатель на буфер
;       rcx - Количество элементов в буфере
; Выходные параметры:
;       rax - Итоговое количество элементов в буфере
; Портящиеся регистры:
;       callee-caller
; -----------------------------------------------------------------------------
itoa:
; --- Start prologue ---
    push    rbp
    mov     rbp, rsp

    push    rbx
; --- End prologue ---

    mov     r10, rdi                    ; Сохраняем число
    mov     r11, rcx                    ; Сохраняем количество элементов в буфере

    cmp     rsi, 10
    je      .decimal_logic              ; 10-я СС обрабатывается отдельно

    push    rdx                         ; Сохраняем содержимое регистра rdx

;   В регистре r8 будет храниться шаг для битового сдвига. Инструкция 
;   bsr найдет индекс наибольшего единичного бита в rsi
    bsr     r8, rsi

    xor     edx, edx
    mov     rax, 64                     ; 64 - количество бит в регистрах r**

;   В регистре rax будет храниться количество разрядов числа в заданной 
;   системе счисления. Делимое лежит в rdx:rax, делитель в r8.
;   rax = 64 / r8
;   rdx = 64 % r8
    div     r8

    cmp     rdx, 0
    je      .skip_inc

;   Если после нахождение шага битового сдвига число 64 поделилось не нацело,
;   то в таком случае надо учесть неполный разряд, который остался.
    inc     rax

.skip_inc:
    mov     rbx, rax

    pop     rdx

    mov     r9, rsi
    dec     r9                          ; r9 = base - 1 - битовая маска

    mov     rcx, r11
    add     rcx, rbx
    cmp     rcx, BUFFER_SIZE

;   Если в буфере достаточно места для числа, то мы не очищаем его
    jb      .skip_print

    mov     rdi, rdx 
    mov     rsi, r11

    sub     rsp, 8

    call    print_buffer

    add     rsp, 8

    xor     r11d, r11d                  ; Обнуляем количество элементов в буфере

.skip_print:

    mov     rax, rbx

    jmp     .condition_1
.loop_1:
    mov     rsi, r10
    and     rsi, r9
    push    rsi

    mov     rcx, r8
    shr     r10, cl

    dec     rax

.condition_1:
    cmp     rax, 0
    jne     .loop_1

    mov     rax, rbx

    jmp     .condition_2
.loop_2:
    pop     rsi
    movzx   rsi, byte [digits + rsi]

    cmp     rsi, '0'
    je      .skip_load_into_buffer

    mov     byte [rdx + r11], sil

    inc     r11

.skip_load_into_buffer:
    dec     rax

.condition_2:
    cmp     rax, 0
    jne     .loop_2

;   Возвращаем из функции текущее количество элементов в буфере
    mov     rax, r11

.decimal_logic:
; --- Start prologue ---
    pop     rbx

    pop     rbp
; --- End prologue ---

    ret 


; -----
;     псевдокод:
;     if ($rsi == 2) {
;         roll_size = 1
;     } elif ($rsi == 8) {
;         roll_size = 3   
;     } elif ($rsi == 16) {
;         roll_size = 4
;     }
;     and_num = $rsi - 1

;     i = 64 / roll_size
;     if (64 % roll_size != 0) {
;         i++
;     }
    
;     ; Если число не поместится в буфер, то очистим содержимое буфера
;     if (idx + i >= BUFFER_SIZE) {
;         print_buffer(buffer, idx)
;         idx = 0
;     }

;     k = i
;     while (k != 0) {
;         ; Example for oct notation
;         num = $rdi
;         and num, and_num  ; 0x0111
;         push num + '0'
;         $rdi >>= roll_size
;         k--
;     }

;     k = i
;     while (i != 0) {
;         pop rdx
;         buffer[idx] = rdx
;         idx++
;     }

;     return idx 


section .note.GNU-stack