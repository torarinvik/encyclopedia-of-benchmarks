module compute_totient;

fn usz decimal_length(long value) {
    usz length = 1;
    while (value >= 10) { value /= 10; length++; }
    return length;
}

fn usz append_decimal(long value, char* output, usz position) {
    char[3] digits;
    usz count = 0;
    do { digits[count++] = (char)('0' + value % 10); value /= 10; } while (value > 0);
    while (count > 0) { count--; output[position++] = digits[count]; }
    return position;
}

fn long compute_totient(long n, char* output, usz output_capacity) @export("compute_totient") {
    if (n < 1 || n > 80) return -1;
    long[80] phi;
    for (long i = 1; i <= n; i++) phi[i - 1] = i;
    for (long p = 2; p <= n; p++) {
        if (phi[p - 1] != p) continue;
        phi[p - 1] = p - 1;
        for (long i = 2 * p; i <= n; i += p)
            phi[i - 1] = (phi[i - 1] / p) * (p - 1);
    }
    usz required = (usz)(n - 1);
    for (long i = 0; i < n; i++) required += decimal_length(phi[i]);
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    for (long i = 0; i < n; i++) {
        if (i > 0) output[position++] = ',';
        position = append_decimal(phi[i], output, position);
    }
    return (long)position;
}
