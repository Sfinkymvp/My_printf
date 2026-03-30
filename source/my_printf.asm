BUFFER_SIZE         equ 128
STDOUT_FD           equ 1


section .rodata

jump_table:
                    dq my_printf_logic.case_b
                    dq my_printf_logic.case_c
                    dq my_printf_logic.case_d
                    times ('o' - 'd' - 1) dq my_printf_logic.case_default
                    dq my_printf_logic.case_o
                    times ('x' - 'o' - 1) dq my_printf_logic.case_default
                    dq my_printf_logic.case_x           


digits              db "0123456789ABCDEF"


section .bss

buffer              resb BUFFER_SIZE
itoa_buffer         resb BUFFER_SIZE


section .text
    global my_printf


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
    push    r14
    push    r15
; --- End prologue --- 
    mov     rbx, rbp        
    add     rbx, 24

; В регистре r12 хранится адрес форматной строки
    mov     r12, [rbx]             
    add     rbx, 8
; В регистре r13 хранится адрес буфера
    mov     r13, buffer          
; В регистре r14 хранится смещение в форматной строке
    xor     r14d, r14d                  
; В регистре r15 хранится размер содержимого буфера
    xor     r15d, r15d

.main_loop:
    movzx   rax, byte [r12 + r14]
    test    rax, rax
    je     .done

    cmp     byte [r12 + r14], '%'
    je      .spec_handler

    movzx   rax, byte [r12 + r14]
    mov     byte [r13 + r15], al
    inc     r14
    inc     r15

.check_buffer:
    cmp     r15, BUFFER_SIZE
    jb      .main_loop

    mov     rdi, r13
    mov     rsi, r15
    call    print_buffer
    xor     r15d, r15d

    jmp     .main_loop

.done:
    mov     byte [r13 + r15], 0         ; Заканчиваем строку ноль-терминатором
    inc     r15                         ; Учитываем ноль-терминатор в длине строки

    mov     rdi, r13
    mov     rsi, r15
    sub     rsp, 8
    call    print_buffer               ; Выводим содержимое буфера в стандартный поток вывода
    add     rsp, 8
    xor     r15d, r15d

; --- Start epilogue --- 
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    pop     rbp
; --- End epilogue --- 
    ret

.number_handler:
    mov     rdi, [rbx]              
    add     rbx, 8
    mov     rdx, itoa_buffer
    xor     ecx, ecx
    call    itoa

    mov     rdx, rax
    add     rdx, r15
    cmp     rdx, BUFFER_SIZE
    jb      .skip_print

    mov     rdi, buffer
    mov     rsi, r15
    call    print_buffer
    xor     r15d, r15d

.skip_print:
    mov     rcx, rax
    xor     eax, eax

.copy_loop:
    movzx   rdx, byte [itoa_buffer + rax]
    mov     byte [buffer + r15], dl
    inc     rax
    inc     r15

.entry_copy_loop:
    loop    .copy_loop

    inc     r14

    jmp     .check_buffer

.spec_handler:
    inc     r14                         ; Переходим к следующему символу в формате
    movzx   rax, byte [r12 + r14]
    sub     rax, 'b'

    lea     rsi, [jump_table]
    jmp     [rsi + rax * 8]

.case_b:
    mov     rsi, 2
    jmp     .number_handler

.case_c:
    movzx   rax, byte [rbx]             ; Получаем символ
    add     rbx, 8

    mov     byte [r13 + r15], al        ; Кладем в буфер символ
    inc     r14
    inc     r15

    jmp     .check_buffer

.case_d:
    mov     rsi, 10
    jmp     .number_handler

.case_o:
    mov     rsi, 8
    jmp     .number_handler

.case_x:
    mov     rsi, 16                 
    jmp     .number_handler

.case_default:
    nop


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
    push    r12
; --- End prologue ---
    xor     r12d, r12d

    mov     r10, rdi                    ; Сохраняем число
    mov     r11, rcx                    ; Сохраняем количество элементов в буфере

    cmp     rsi, 10
    je      .decimal_logic              ; 10-я СС обрабатывается отдельно

    push    rdx                         ; Сохраняем содержимое регистра rdx
; В регистре r8 хранится шаг для битового сдвига. Инструкция 
; bsr найдет индекс наибольшего единичного бита в rsi
    bsr     r8, rsi
    xor     edx, edx
    mov     rax, 64                     ; 64 - количество бит в регистрах r**
; В регистре rax хранится количество разрядов числа в заданной 
; системе счисления. Делимое лежит в rdx:rax, делитель в r8.
; rax = 64 / r8
; rdx = 64 % r8
    div     r8

    test    rdx, rdx
    je      .skip_inc
; Если после нахождение шага битового сдвига число 64 поделилось не нацело,
; то в таком случае надо учесть неполный разряд, который остался.
    inc     rax

.skip_inc:
    pop     rdx
    mov     rbx, rax

    mov     r9, rsi
    dec     r9                          ; r9 = base - 1 - битовая маска

    mov     rcx, r11
    add     rcx, rbx
    cmp     rcx, BUFFER_SIZE
; Если в буфере достаточно места для числа, то мы не очищаем его
    jb      .skip_print

    mov     rdi, rdx 
    mov     rsi, r11
    sub     rsp, 8
    call    print_buffer
    add     rsp, 8
    xor     r11d, r11d                  ; Обнуляем количество элементов в буфере

.skip_print:
    mov     rcx, r8
    mov     rax, rbx

.loop_1:
    mov     rsi, r10
    and     rsi, r9
    push    rsi
    shr     r10, cl

    dec     rax
    jne     .loop_1

    mov     rcx, rbx

.loop_2:
    pop     rsi

    test    rsi, rsi
    jne     .is_significant

    test    r12, r12
    je      .condition_2

.is_significant:
    movzx   rsi, byte [digits + rsi]
    mov     byte [rdx + r11], sil
    inc     r11
; Если значение r12 не нулевое, значит встречались значащие цифры
    inc     r12

.condition_2:
    loop    .loop_2

    test    r11, r11
    jne     .done

    mov     byte [rdx + r11], '0'
    mov     r11, 1

.done:
; Возвращаем из функции текущее количество элементов в буфере
    mov     rax, r11

.decimal_logic:
; --- Start prologue ---
    pop     r12
    pop     rbx

    pop     rbp
; --- End prologue ---

    ret 


section .note.GNU-stack