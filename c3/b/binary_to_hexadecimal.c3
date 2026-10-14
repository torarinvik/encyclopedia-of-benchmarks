module binary_to_hexadecimal;

// Convert a most-significant-first bit array to radix 16 text.
fn long binary_to_hexadecimal(long* bits, usz length, char* output, usz output_capacity)
    @export("binary_to_hexadecimal")
{
    if (length == 0 || length > 63) return -1;
    long value = 0;
    for (usz index = 0; index < length; index++) {
        long bit = bits[index];
        if (bit < 0 || bit > 1) return -1;
        value = value * 2 + bit;
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
