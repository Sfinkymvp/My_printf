#include <stdio.h>


extern void my_printf(const char* format, ...);


int main()
{
    char* format_string = "Hello! Char: %c, Bin: %b, Oct: %o, Dec: %d, Hex: %x, String: %s\n";
    my_printf(format_string,
        'm', 0xAB, 012345, -123, 0xabcd0123, "I'm using wsl");

    printf(format_string,
        'm', 0xAB, 012345, -123, 0xabcd0123, "I'm using wsl");

    return 0;
}