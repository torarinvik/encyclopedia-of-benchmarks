module logarithmic_series;

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

fn bool has_negative_sign(long delta, long term) {
    return delta < 0 ? term % 2 == 1 : term % 2 == 0;
}

fn long logarithmic_series(long* values, usz length, char* output,
                           usz output_capacity) @export("logarithmic_series") {
    if (values == null || length != 2) return -1;
    long x_value = values[0], n_terms = values[1];
    if (x_value < -10 || x_value > 10 || n_terms < -64 || n_terms > 256) return -1;
    if (n_terms <= 0) return 0;
    long delta = x_value - 1;
    long base = delta < 0 ? -delta : delta;
    usz needed = 0;
    for (long term = 1; term <= n_terms; term++)
        needed += (has_negative_sign(delta, term) ? 2 : 1) + decimal_width(base)
                  + 2 * decimal_width(term) + 4;
    if (output == null || output_capacity < needed) return -2;
    usz position = 0;
    for (long term = 1; term <= n_terms; term++) {
        if (has_negative_sign(delta, term)) output[position++] = '-';
        output[position++] = '(';
        position = append_decimal(output, position, base);
        output[position++] = '^';
        position = append_decimal(output, position, term);
        output[position++] = ')'; output[position++] = '/';
        position = append_decimal(output, position, term);
        output[position++] = '\n';
    }
    return (long)position;
}
