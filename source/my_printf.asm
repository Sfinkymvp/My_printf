section .text
    global my_printf


BUFFER_SIZE         equ 128
STDOUT_FD           equ 1


my_printf:
    pop r10                             ; Сохраняем адрес возврата

    push    r9                          ; 6-й аргумент
    push    r8                          ; 5-й аргумент
    push    rcx                         ; 4-й аргумент
    push    rdx                         ; 3-й аргумент
    push    rsi                         ; 2-й аргумент
    push    rdi                         ; 1-й аргумент (Форматная строка)
           
    sub     rsp, 8

    call    my_printf_logic

    add     rsp, 56
    push    r10                         ; Кладем обратно адрес возврата

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

    ; cmp     [rdi + rcx], '\'
    ; je      .escape_handler

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

    xor     r8d, r8d
    mov     r8b, byte [rbx]             ; Получаем символ
    add     rbx, 8

    mov     byte [r13 + rdx], r8b       ; Кладем в буфер символ
    inc     rcx
    inc     rdx
    jmp      .continue

.hex_handler:
    xor     eax, eax

    xor     r8d, r8d
    mov     r8, [rbx]                   ; Получаем число
    add     rbx, 8

    mov     rdi, r8
    mov     rsi, 16                     ; Указываем систему счисления для записи числа

    sub     rsp, 8

    call    itoa

    jmp     .continue

.continue:
    jmp     .next_loop

.done:
    mov     byte [r13 + rdx], 0x00      ; Заканчиваем строку ноль-терминатором
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
;       rsi - Количество символов для вывода
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
;       rsi - Основание системы счисления (Оно должно быть степенью двойки)
; Выходные параметры:
;       Нет
; Портящиеся регистры:
;       callee-caller
; -----------------------------------------------------------------------------
itoa:


section .bss

buffer              resb BUFFER_SIZE

section .note.GNU-stack