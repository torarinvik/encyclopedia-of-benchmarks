module factorize;

fn usz factor_pairs(long value, uint* primes, uint* exponents) {
    if (value <= 1) { primes[0] = (uint)value; exponents[0] = 1; return 1; }
    usz count = 0;
    long remaining = value;
    for (long divisor = 2; divisor <= remaining / divisor; divisor++) {
        if (remaining % divisor == 0) {
            uint exponent = 0;
            do { remaining /= divisor; exponent++; } while (remaining % divisor == 0);
            primes[count] = (uint)divisor;
            exponents[count++] = exponent;
        }
    }
    if (remaining > 1) {
        primes[count] = (uint)remaining;
        exponents[count++] = 1;
    }
    return count;
}

fn void write_u32le(uint value, char* output, usz position) {
    for (usz byte = 0; byte < 4; byte++) {
        output[position + byte] = (char)((value >> (8 * byte)) & 255);
    }
}

// Encode ascending prime/exponent pairs as little-endian uint values.
fn long factorize(long value, char* output, usz output_capacity) @export("factorize") {
    if (value < 0 || value > 1000005) return -1;
    uint[10] primes;
    uint[10] exponents;
    usz count = factor_pairs(value, &primes[0], &exponents[0]);
    usz required = count * 8;
    if (output == null || output_capacity < required) return -2;
    for (usz i = 0; i < count; i++) {
        write_u32le(primes[i], output, 8 * i);
        write_u32le(exponents[i], output, 8 * i + 4);
    }
    return (long)required;
}
