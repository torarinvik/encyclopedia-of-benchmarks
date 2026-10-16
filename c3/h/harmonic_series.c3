module harmonic_series;

fn usz append_decimal(char* output, usz position, usz value) {
    char[4] digits; usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value != 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

fn long harmonic_series(long n, char* output, usz capacity) @export("harmonic_series") {
    if (n < -512 || n > 512) return -1;
    if (n <= 0) return 0;
    usz needed = 2;
    for (usz term = 2; term <= (usz)n; term++) {
        usz value = term, digits = 0;
        do { digits++; value /= 10; } while (value != 0);
        needed += digits + 3;
    }
    if (output == null || capacity < needed) return -2;
    usz position = 0; output[position++] = '1'; output[position++] = '\n';
    for (usz term = 2; term <= (usz)n; term++) {
        output[position++] = '1'; output[position++] = '/';
        position = append_decimal(output, position, term);
        output[position++] = '\n';
    }
    return (long)position;
}
