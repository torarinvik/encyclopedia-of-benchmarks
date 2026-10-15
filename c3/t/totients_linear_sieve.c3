module totients_linear_sieve;

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

fn long totients_linear_sieve(long n, char* output, usz output_capacity) @export("totients_linear_sieve") {
    if (n < 1 || n > 80) return -1;
    long[81] phi;
    long[81] composite;
    long[80] primes;
    for (long i = 0; i <= n; i++) { phi[i] = 0; composite[i] = 0; }
    usz prime_count = 0;
    phi[1] = 1;
    for (long i = 2; i <= n; i++) {
        if (composite[i] == 0) { primes[prime_count++] = i; phi[i] = i - 1; }
        for (usz j = 0; j < prime_count; j++) {
            long p = primes[j];
            if (i * p > n) break;
            composite[i * p] = 1;
            if (i % p == 0) { phi[i * p] = phi[i] * p; break; }
            phi[i * p] = phi[i] * (p - 1);
        }
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
