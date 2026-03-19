section .text
    extern my_printf
    global _start


BUFFER_SIZE     equ 1024


_start:
    ; mov     rax, 0              ; Системный вызов read
    ; mov     rdi, 0              ; Файловый дескриптор stdin
    ; mov     rsi, input_buffer   ; Буфер для ввода
    ; mov     rdx, BUFFER_SIZE
    ; syscall

    mov     rdi, 'H'
    call    my_printf 

    mov     rdi, 0x0A
    call    my_printf

    mov     rax, 60             ; Системный вызов exit
    xor     rdi, rdi            ; Код возврата 0
    syscall


section .bss


input_buffer resb BUFFER_SIZE