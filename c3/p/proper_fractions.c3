module proper_fractions;

fn long gcd_u64(long left, long right) {
    while (right != 0) { long remainder = left % right; left = right; right = remainder; }
    return left;
}

fn usz decimal_width(long value) {
    usz width = 1;
    while (value >= 10) { value /= 10; width++; }
    return width;
}

fn usz append_decimal(char* output, usz position, long value) {
    char[20] digits; usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value != 0);
    while (count > 0) { count--; output[position++] = digits[count]; }
    return position;
}

fn long proper_fractions(long* values, usz length, char* output,
                         usz output_capacity) @export("proper_fractions") {
    if (values == null || length != 1) return -1;
    long denominator = values[0];
    if (denominator < 0 || denominator > 256) return -1;
    if (denominator <= 1) return 0;
    usz needed = 0;
    for (long numerator = 1; numerator < denominator; numerator++)
        if (gcd_u64(numerator, denominator) == 1)
            needed += decimal_width(numerator) + decimal_width(denominator) + 2;
    if (output == null || output_capacity < needed) return -2;
    usz position = 0;
    for (long numerator = 1; numerator < denominator; numerator++) {
        if (gcd_u64(numerator, denominator) != 1) continue;
        position = append_decimal(output, position, numerator);
        output[position++] = '/';
        position = append_decimal(output, position, denominator);
        output[position++] = '\n';
    }
    return (long)position;
}
