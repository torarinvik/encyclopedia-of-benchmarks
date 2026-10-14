module decimal_to_hexadecimal;

// Write lowercase hexadecimal digits of a nonnegative signed 64-bit input.
fn long decimal_to_hexadecimal(long value, char* output, usz output_capacity)
    @export("decimal_to_hexadecimal")
{
    if (value < 0) return -1;
    usz width = 1;
    for (long remaining = value; remaining >= 16; remaining /= 16) width++;
    if (output == null || output_capacity < width) return -2;
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
