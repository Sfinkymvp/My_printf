extern void my_printf(const char* format, ...);


int main()
{
    my_printf("Hello, Aboba!\nSymbol: %c\nHex digit: %x\n", 'x', 0x12);
    my_printf("\nIdi nahyi, digit %x\n", 0xfabcdefff);

    return 0;
}