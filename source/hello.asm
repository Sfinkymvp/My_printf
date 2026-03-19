section .text
    global _start

_start:
    mov rax, 1                             ; Номер системного вызова write
    mov rdi, 1                             ; Файловый дескриптор stdout
    mov rsi, msg                           ; Адрес строки msg
    mov rdx, msg_len                       ; Длина строки
    syscall                                ; Вызов ядра

    mov rax, 60                            ; Номер системного вызова exit
    mov rdi, 0                             ; Код возврата 0
    syscall

section .data
    msg         db "Hello, Nasm!", 0x0A    ; Строка с символом новой строки 
    msg_len     equ $ - msg