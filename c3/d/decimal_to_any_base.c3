module decimal_to_any_base;

// Convert a nonnegative signed 64-bit value to base 2 through 36.
fn long decimal_to_any_base(long* input, usz length, char* output, usz output_capacity)
    @export("decimal_to_any_base")
{
    if (length != 2) return -1;
    long value = input[0];
    long base = input[1];
    if (value < 0 || base < 2 || base > 36) return -1;
    usz width = 1;
    for (long remaining = value; remaining >= base; remaining /= base) width++;
    if (output_capacity < width) return -2;
    usz position = width;
    long remaining = value;
    while (position > 0) {
        position--;
        long digit = remaining % base;
        output[position] = (char)(digit < 10 ? '0' + digit : 'A' + digit - 10);
        remaining /= base;
    }
    return (long)width;
}
