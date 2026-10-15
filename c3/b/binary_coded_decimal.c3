module binary_coded_decimal;

// Write the prefixed four-bit-per-decimal-digit BCD representation.
fn long binary_coded_decimal(long value, char* output, usz output_capacity)
    @export("binary_coded_decimal") {
    if (value < -2147483648 || value > 2147483647) return -1;
    if (value < 0) value = 0;

    char digits[10];
    usz digit_count = 0;
    do {
        digits[digit_count] = (char)(value % 10);
        digit_count++;
        value /= 10;
    } while (value > 0);

    usz output_length = 2 + digit_count * 4;
    if (output == null || output_capacity < output_length) return -2;
    output[0] = '0';
    output[1] = 'b';
    usz position = 2;
    while (digit_count > 0) {
        digit_count--;
        char digit = digits[digit_count];
        for (int bit = 3; bit >= 0; bit--) {
            output[position] = (char)('0' + ((digit >> bit) & 1));
            position++;
        }
    }
    return (long)output_length;
}
