module decimal_to_gray;

// Write the minimal-width ASCII binary form of n ^ (n >> 1).
fn long decimal_to_gray(long value, char* output, usz output_capacity)
    @export("decimal_to_gray")
{
    if (value < 0) return -1;

    long gray = value ^ (value >> 1);
    usz width = 1;
    for (long remaining = gray; remaining > 1; remaining /= 2) width++;
    if (output == null || output_capacity < width) return -2;

    usz position = width;
    long remaining = gray;
    while (position > 0) {
        position--;
        output[position] = (char)('0' + remaining % 2);
        remaining /= 2;
    }
    return (long)width;
}
