extern void my_printf(const char* format, ...);


int main()
{
    my_printf("Hello aboba!\n");
    my_printf("Bin: %b\n", 0xAB);
    my_printf("Oct: %o\n", 012345);
    my_printf("Dec: %d\n", -123);
    my_printf("Hex: %x\n", 0xdcba0123);
    my_printf("String: %s\n", "Hello, World!");

    return 0;
}