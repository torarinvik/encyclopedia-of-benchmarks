module decimal_to_binary;

// Write the most-significant-first binary representation of a nonnegative i64.
fn long decimal_to_binary(long value, char* output, usz output_capacity)
    @export("decimal_to_binary")
{
    if (value < 0) return -1;
    usz width = 1;
    for (long remaining = value; remaining > 1; remaining /= 2) width++;
    if (output == null || output_capacity < width) return -2;

    usz position = width;
    long remaining = value;
    while (position > 0) {
        position--;
        output[position] = (char)('0' + remaining % 2);
        remaining /= 2;
    }
    return (long)width;
}
