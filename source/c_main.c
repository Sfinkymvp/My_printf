#include <stdio.h>


extern void my_printf(const char* format, ...);


int main()
{
    my_printf("Char: %c, Bin: %b, Oct: %o, Dec: %d, Hex: %x, String: %s, Float: %f, Percent: %%, Char: %c\n"
    "%d %s %x %d %% %c %b\n" "%d %s %x %d %% %c %b\n",
        'm', 0b1111100011111, 012345, -123, 0xabcd0123, "Hello", 3.14, 'i',
        -1, "love", 3802, 100, 33, 126,
        -1, "love", 3802, 100, 33, 126);

    return 0;
}