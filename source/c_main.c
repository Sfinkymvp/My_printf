#include <stdio.h>


extern void my_printf(const char* format, ...);


int main()
{
    char* format_string = "Hello! Char: %c, Bin: %b, Oct: %o, Dec: %d, Hex: %x, String: %s\n";
    my_printf(format_string,
        'm', 0xAB, 012345, -123, 0xabcd0123, "I'm using wsl");

    printf(format_string,
        'm', 0xAB, 012345, -123, 0xabcd0123, "I'm using wsl");

    int value = -1;
    char* string = "abc\ndef";
    my_printf("Goodbye\n"
              "%d %o %x\n"
              "%s %c\n"
              "%d %s %x %d%c\n",
        value, value, value, string, 'T', value, "love", 3802, 100, 33);

    my_printf("Float: %f\n", 0.5);

    return 0;
}