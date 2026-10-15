module prime_factorization;

fn usz factor_pairs(long value, u32* primes, u32* exponents) {
    usz count = 0;
    long remaining = value;
    for (long divisor = 2; divisor <= remaining / divisor; divisor++) {
        if (remaining % divisor == 0) {
            u32 exponent = 0;
            do { remaining /= divisor; exponent++; } while (remaining % divisor == 0);
            primes[count] = divisor.u32();
            exponents[count++] = exponent;
        }
    }
    if (remaining > 1) {
        primes[count] = remaining.u32();
        exponents[count++] = 1;
    }
    return count;
}

fn void write_u32le(u32 value, char* output, usz position) {
    for (usz byte = 0; byte < 4; byte++)
        output[position + byte] = ((value >> (8 * byte)) & 255).u8();
}

// Encode ascending prime/exponent pairs as little-endian u32 values.
fn long prime_factorization(long value, char* output, usz output_capacity) @export("prime_factorization") {
    if (value < 1 || value > 1000005) return -1;
    u32[10] primes;
    u32[10] exponents;
    usz count = factor_pairs(value, &primes[0], &exponents[0]);
    usz required = count * 8;
    if (output == null || output_capacity < required) return -2;
    for (usz i = 0; i < count; i++) {
        write_u32le(primes[i], output, 8 * i);
        write_u32le(exponents[i], output, 8 * i + 4);
    }
    return required.long();
}
