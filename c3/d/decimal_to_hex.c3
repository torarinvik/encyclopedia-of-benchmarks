module decimal_to_hex;

fn long decimal_to_hex(long value, char* output, usz capacity) @export("decimal_to_hex") {
    if (value < 0 || value > 9007199254740991) return -1;
    usz width = 1;
    for (long n = value; n >= 16; n /= 16) width++;
    if (output == null || capacity < width) return -2;
    usz position = width;
    do {
        long digit = value % 16;
        output[--position] = (char)(digit < 10 ? '0' + digit : 'A' + digit - 10);
        value /= 16;
    } while (position > 0);
    return (long)width;
}
