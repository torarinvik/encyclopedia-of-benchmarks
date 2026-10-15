module binary_to_gray;

// Convert an ASCII binary string to equal-width ASCII Gray code.
fn long binary_to_gray(long* bits, usz length, char* output, usz output_capacity)
    @export("binary_to_gray")
{
    if (bits == null || length == 0 || length > 66) return -1;
    for (usz index = 0; index < length; index++)
        if (bits[index] != '0' && bits[index] != '1') return -1;
    if (output == null || output_capacity < length) return -2;
    for (usz index = 0; index < length; index++) {
        long current = bits[index] - '0';
        long previous = index == 0 ? 0 : bits[index - 1] - '0';
        output[index] = (char)('0' + (current ^ previous));
    }
    return (long)length;
}
