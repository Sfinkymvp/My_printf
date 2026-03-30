extern void my_printf(const char* format, ...);


int main()
{
    my_printf("Hello aboba!\n");
    my_printf("Bin: %b\n", 0x0230234);
    my_printf("Oct: %o\n", 0x050423);
    my_printf("Hex: %x\n", 0xabcdeffedcba0123);

    return 0;
}