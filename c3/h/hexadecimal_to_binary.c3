module hexadecimal_to_binary;

// Convert a most-significant-first hexadecimal digit array to radix 2 text.
fn long hexadecimal_to_binary(long* digits, usz length, char* output, usz output_capacity)
    @export("hexadecimal_to_binary")
{
    if (length == 0 || length > 16) return -1;
    if (length == 16 && digits[0] > 7) return -1;
    long value = 0;
    for (usz index = 0; index < length; index++) {
        long hex_digit = digits[index];
        if (hex_digit < 0 || hex_digit > 15) return -1;
        value = value * 16 + hex_digit;
    }
    usz width = 1;
    for (long remaining = value; remaining >= 2; remaining /= 2) width++;
    if (output_capacity < width) return -2;
    usz position = width;
    long remaining = value;
    while (position > 0) {
        position--;
        long digit = remaining % 2;
        output[position] = (char)(digit < 10 ? '0' + digit : 'a' + digit - 10);
        remaining /= 2;
    }
    return (long)width;
}
