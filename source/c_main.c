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
    my_printf("Percent: %%\n");

    // my_printf("NaN: %f\n", 0.0 / -0.0);
    // my_printf("inf: %f\n", 1.0 / 0);

    my_printf("1: %f, 2: %d, 3: %f, 4: %d, 5: %f, 6: %d, 7: %f, 8: %d, 9: %f, 10: %d\n"
        "11: %f, 12: %d, 13: %f, 14: %d, 15: %f\n",
        1.0, 2, 3.0, 4, 5.0, 6, 7.0, 8, 9.0, 10, 11.0, 12, 13.0, 14, 15.0);
    
    return 0;
}