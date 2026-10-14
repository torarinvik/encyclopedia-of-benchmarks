module base_neg2_conversion;

// Convert a signed 64-bit integer to canonical negabinary digits.
fn long base_neg2_conversion(long* input, usz length, char* output, usz output_capacity)
    @export("base_neg2_conversion")
{
    if (length != 1) return -1;
    long width = 0;
    long remaining = input[0];
    do {
        long quotient = remaining / -2;
        long digit = remaining % -2;
        if (digit < 0) { digit += 2; quotient++; }
        remaining = quotient;
        width++;
    } while (remaining != 0);
    if (output_capacity < (usz)width) return -2;
    usz top = 0;
    remaining = input[0];
    do {
        long quotient = remaining / -2;
        long digit = remaining % -2;
        if (digit < 0) { digit += 2; quotient++; }
        output[top++] = (char)('0' + digit);
        remaining = quotient;
    } while (remaining != 0);
    usz left = 0;
    usz right = top - 1;
    while (left < right) { char tmp = output[left]; output[left] = output[right]; output[right] = tmp; left++; right--; }
    return (long)top;
}
