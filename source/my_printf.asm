BUFFER_SIZE         equ 128
STDOUT_FD           equ 1
NUMBER_OF_BITS      equ 32


section .rodata

jump_table:
                    dq my_printf_logic.case_b
                    dq my_printf_logic.case_c
                    dq my_printf_logic.case_d
                    times ('o' - 'd' - 1) dq my_printf_logic.case_default
                    dq my_printf_logic.case_o
                    times ('s' - 'o' - 1) dq my_printf_logic.case_default
                    dq my_printf_logic.case_s
                    times ('x' - 's' - 1) dq my_printf_logic.case_default
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
    inc     r14
    mov     rdi, [rbx]              
    add     rbx, 8
    mov     rdx, itoa_buffer
    xor     ecx, ecx
    call    itoa

    mov     rdx, rax
    add     rdx, r15
    cmp     rdx, BUFFER_SIZE
    jb      .skip_print

    call    .flush_buffer

.skip_print:
    mov     rcx, rax
    xor     eax, eax

.number_copy_loop:
    movzx   rdx, byte [itoa_buffer + rax]
    mov     byte [buffer + r15], dl
    inc     rax
    inc     r15
    loop    .number_copy_loop

    jmp     .check_buffer

.spec_handler:
    inc     r14                         ; Переходим к следующему символу в формате
    movzx   rax, byte [r12 + r14]
    sub     rax, 'b'

    lea     rsi, [jump_table]
    jmp     [rsi + rax * 8]

.string_handler:
    inc     r14
    mov     rdi, [rbx]
    add     rbx, 8
    call    string_len
    mov     rcx, rax

    test    rcx, rcx
    je      .main_loop

    cmp     rcx, BUFFER_SIZE
    jae     .print_direct

    add     rcx, r15
    cmp     rcx, BUFFER_SIZE
    jb      .move_to_buffer

    call    .flush_buffer

.move_to_buffer:
    mov     rcx, rax
    xor     eax, eax

.string_copy_loop:
    movzx   rdx, byte [rdi + rax]
    mov     byte [r13 + r15], dl
    inc     rax
    inc     r15
    loop    .string_copy_loop

    jmp     .check_buffer

.print_direct:
    mov     rsi, rcx
    call    print_buffer
    jmp     .main_loop

.flush_buffer:
    push    rdi
    push    rsi

    mov     rdi, r13
    mov     rsi, r15
    call    print_buffer
    xor     r15d, r15d

    pop     rsi
    pop     rdi

    ret

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

.case_s:
    jmp     .string_handler

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
; Procedure: string_len
; -----------------------------------------------------------------------------
; Описание:
;       Находит длину строки, оканчивающейся ноль-терминатором
; Входные параметры:
;       rdi - Указатель на строку
; Выходные параметры:
;       rax - Длина строки
; Портящиеся регистры:
;       callee-caller
; -----------------------------------------------------------------------------
string_len:
    xor     ecx, ecx
.counting_loop:
    movzx   rax, byte [rdi + rcx]
    test    rax, rax
    je      .exit

    inc     rcx
    jmp     .counting_loop

.exit:
    mov     rax, rcx
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
; 10-я СС обрабатывается отдельно
    cmp     rsi, 10
    je      .decimal_logic              

    call    itoa_power2
    jmp     .exit

.decimal_logic:
    call    itoa_decimal
    jmp     .exit

.exit:
; В регистре rax уже лежит итоговое количество элементов в буфере
    ret 


; -----------------------------------------------------------------------------
; Procedure: itoa_power2
; -----------------------------------------------------------------------------
; Описание:
;       Осуществляет запись числа в буфер в системе счисления со степенью двойки
; Входные параметры:
;       rdi - Число
;       rsi - Основание системы счисления (2, 8, 16)
;       rdx - Указатель на буфер
;       rcx - Количество элементов в буфере
; Выходные параметры:
;       rax - Итоговое количество элементов в буфере
; Портящиеся регистры:
;       callee-caller
; -----------------------------------------------------------------------------
itoa_power2:
; --- Start prologue ---
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
; --- End prologue ---

; В регистре r13 хранится указатель на буфер
    mov     r13, rdx   
; В регистре r14 хранится количество элементов в буфере
    mov     r14, rcx
; В регистре r15 хранится число 
    mov     r15, rdi
; В регистре r8 хранится шаг для битового сдвига. Инструкция 
; bsr найдет индекс наибольшего единичного бита в rsi
    bsr     r8, rsi
    xor     edx, edx
    mov     rax, NUMBER_OF_BITS
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
    mov     rbx, rax

    mov     r9, rsi
; r9 = base - 1 - битовая маска
    dec     r9                          

    mov     rcx, r8
    mov     rax, rbx
.loop_1:
    mov     rsi, r15
    and     rsi, r9
    push    rsi
    shr     r15, cl

    dec     rax
    jne     .loop_1

    mov     rcx, rbx
    xor     r12d, r12d
.loop_2:
    pop     rsi

    test    rsi, rsi
    jne     .is_significant

    test    r12, r12
    je      .condition_2

.is_significant:
    movzx   rsi, byte [digits + rsi]
    mov     byte [r13 + r14], sil
    inc     r14
; Если значение r12 не нулевое, значит встречались значащие цифры
    inc     r12

.condition_2:
    loop    .loop_2

    test    r14, r14
    jne     .exit

    mov     byte [r13 + r14], '0'
    mov     r14, 1

.exit:
    mov     rax, r14
; --- Start epilogue ---
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    pop     rbp
; --- End epilogue ---

    ret 


; -----------------------------------------------------------------------------
; Procedure: itoa_decimal
; -----------------------------------------------------------------------------
; Описание:
;       Осуществляет запись числа в буфер в десятичной системе счисления
; Входные параметры:
;       rdi - Число
;       rsi - Основание системы счисления (10)
;       rdx - Указатель на буфер
;       rcx - Количество элементов в буфере
; Выходные параметры:
;       rax - Итоговое количество элементов в буфере
; Портящиеся регистры:
;       callee-caller
; -----------------------------------------------------------------------------
itoa_decimal:
; --- Start prologue ---
    push    rbp
    mov     rbp, rsp

    push    r13
    push    r14
; --- End prologue ---

; В регистре r13 хранится указатель на буфер
    mov     r13, rdx   
; В регистре r14 хранится количество элементов в буфере
    mov     r14, rcx

    mov     eax, edi
    test    eax, eax
    jge     .loop_1

    mov     byte [r13 + r14], '-'
    inc     r14
    neg     eax

    xor     ecx, ecx
    mov     esi, 10
.loop_1:
    xor     edx, edx
    div     rsi

    push    rdx
    inc     rcx

    test    eax, eax
    jne     .loop_1

.loop_2:
    pop     rax
    movzx   rdx, byte [digits + rax]
    mov     byte [r13 + r14], dl
    inc     r14
    loop    .loop_2

    mov     rax, r14
; --- Start epilogue ---
    pop     r14
    pop     r13

    pop     rbp
; --- End epilogue ---

    ret 




section .note.GNU-stack