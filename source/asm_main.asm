section .text
    extern my_printf
    extern printf
    global main


BUFFER_SIZE         equ 1024


main:
    sub     rsp, 8

    lea     rdi, [rel format_1]
    mov     rsi, -1
    lea     rdx, [rel string_1]
    mov     rcx, 3802
    mov     r8, 100
    mov     r9, 33
    call    my_printf 

    add     rsp, 8

; -----------------------------------------------------------------------------

    sub     rsp, 8

    lea     r10, [rel string_2]
    xor     eax, eax
    mov     al, 1

    lea     rdi, [rel format_2]
    mov     rsi, 'm'
    mov     rdx, 1111100011111b
    mov     rcx, 12345o
    mov     r8, -123
    mov     r9, 0xabcd0123
    push    'i'
    push    r10
    movsd   xmm0, [rel pi_val]
    call    my_printf 
    add     rsp, 24

; -----------------------------------------------------------------------------

    mov     rax, 60 
    xor     rdi, rdi
    syscall


section .rodata


format_1            db "%d %s %x %d%c %%", 10, 0
string_1            db "love", 0

format_2            db "Char: %c, Bin: %b, Oct: %o, Dec: %d, Hex: %x, String: %s, Float: %f, Percent: %%, Char: %c", 10, 0
string_2            db "Hello", 0

pi_val              dq 3.14


section .note.GNU-stack