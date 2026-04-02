#include <stdio.h>


extern void my_printf(const char* format, ...);


int main()
{
    my_printf("Char: %c, Bin: %b, Oct: %o, Dec: %d, Hex: %x, String: %s, Float: %f, Percent: %%, Char: %c\n",
        'm', 0b1111100011111, 012345, -123, 0xabcd0123, "Hello", 3.14, 'i');

    my_printf("%d %s %x %d%c %%\n",
        -1, "love", 3802, 100, 33);

    return 0;
}