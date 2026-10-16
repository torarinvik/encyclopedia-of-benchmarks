module p_series;

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

fn long term_power(usz term, long power) {
    long result = 1;
    for (long index = 0; index < power; index++) result *= (long)term;
    return result;
}

fn long p_series(long* values, usz length, char* output, usz output_capacity) @export("p_series") {
    if (values == null || length != 2) return -1;
    long nth_term = values[0], power = values[1];
    if (nth_term < -256 || nth_term > 256 || power < 0 || power > 7) return -1;
    if (nth_term <= 0) return 0;
    usz needed = 2;
    for (usz term = 2; term <= (usz)nth_term; term++)
        needed += 5 + decimal_width(term_power(term, power));
    if (output == null || output_capacity < needed) return -2;
    usz position = 0;
    output[position++] = '1'; output[position++] = '\n';
    for (usz term = 2; term <= (usz)nth_term; term++) {
        output[position++] = '1'; output[position++] = ' ';
        output[position++] = '/'; output[position++] = ' ';
        position = append_decimal(output, position, term_power(term, power));
        output[position++] = '\n';
    }
    return (long)position;
}
