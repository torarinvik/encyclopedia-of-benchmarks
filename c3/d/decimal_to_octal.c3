module decimal_to_octal;

// Write the octal digits of a nonnegative signed 64-bit input.
fn long decimal_to_octal(long value, char* output, usz output_capacity)
    @export("decimal_to_octal")
{
    if (value < 0) return -1;
    usz width = 1;
    for (long remaining = value; remaining >= 8; remaining /= 8) width++;
    if (output == null || output_capacity < width) return -2;
    usz position = width;
    long remaining = value;
    while (position > 0) {
        position--;
        output[position] = (char)('0' + remaining % 8);
        remaining /= 8;
    }
    return (long)width;
}
