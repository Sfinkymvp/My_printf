section .text
    global my_printf


; Функция, которая пока что просто печатает символ в stdout
; Символ в rdi
my_printf:
    push    rdi             ; Сохраняем переданный символ в стек
    mov     rax, 1          ; Системный вызов write
    mov     rdi, 1          ; Файловый дескриптор stdout
    mov     rsi, rsp        ; Переданный символ
    mov     rdx, 1          ; Количество символов для печати
    syscall           

    pop     rdi
    ret