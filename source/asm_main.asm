section .text
    extern my_printf
    extern printf
    global main


BUFFER_SIZE         equ 1024


main:
    mov     rdi, format
    mov     rsi, 'm'
    mov     rdx, 0xAB
    mov     rcx, 012345
    mov     r8,  -123
    mov     r9,  0xabcd0123
    push    string
    call    my_printf 
    pop     rax

    xor     eax, eax
    mov     rdi, format
    mov     rsi, 'm'
    mov     rdx, 0xAB
    mov     rcx, 012345
    mov     r8,  -123
    mov     r9,  0xabcd0123
    push    string
    call    printf 
    pop     rax

    mov     rax, 60             ; Системный вызов exit
    xor     rdi, rdi            ; Код возврата 0
    syscall


section .rodata

format              db "Hello! Char: %c, Bin: %b, Oct: %o, Dec: %d, Hex: %x, String: %s", 10, 0
string              db "I'm using wsl", 0


section .note.GNU-stack