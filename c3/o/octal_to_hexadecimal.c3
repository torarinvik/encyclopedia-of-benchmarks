module octal_to_hexadecimal;

// Convert a most-significant-first octal digit array to radix 16 text.
fn long octal_to_hexadecimal(long* digits, usz length, char* output, usz output_capacity)
    @export("octal_to_hexadecimal")
{
    if (length == 0 || length > 21) return -1;
    long value = 0;
    for (usz index = 0; index < length; index++) {
        long octal_digit = digits[index];
        if (octal_digit < 0 || octal_digit > 7) return -1;
        value = value * 8 + octal_digit;
    }
    usz width = 1;
    for (long remaining = value; remaining >= 16; remaining /= 16) width++;
    if (output_capacity < width) return -2;
    usz position = width;
    long remaining = value;
    while (position > 0) {
        position--;
        long digit = remaining % 16;
        output[position] = (char)(digit < 10 ? '0' + digit : 'a' + digit - 10);
        remaining /= 16;
    }
    return (long)width;
}
