module euler_totient_sequence;

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

fn long euler_totient_sequence(long n, char* output, usz output_capacity) @export("euler_totient_sequence") {
    if (n < 1 || n > 80) return -1;
    long[81] phi;
    for (long value = 1; value <= n; value++) {
        long remaining = value;
        long totient = value;
        for (long p = 2; p * p <= remaining; p++) {
            if (remaining % p != 0) continue;
            do { remaining /= p; } while (remaining % p == 0);
            totient -= totient / p;
        }
        if (remaining > 1) totient -= totient / remaining;
        phi[value] = totient;
    }
    usz required = (usz)(n - 1);
    for (long i = 1; i <= n; i++) required += decimal_length(phi[i]);
    if (output == null || output_capacity < required) return -2;
    usz position = 0;
    for (long i = 1; i <= n; i++) {
        if (i > 1) output[position++] = ',';
        position = append_decimal(phi[i], output, position);
    }
    return (long)position;
}
