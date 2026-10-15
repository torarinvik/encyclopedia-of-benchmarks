module prime_factorization_sieve;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

fn void write_u32le(u32 value, char* output, usz position) {
    for (usz byte = 0; byte < 4; byte++)
        output[position + byte] = ((value >> (8 * byte)) & 255).u8();
}

// Sieve through n, then emit ascending prime/exponent pairs as little-endian u32 values.
fn long prime_factorization_sieve(long value, char* output, usz output_capacity)
        @export("prime_factorization_sieve") {
    if (value < 1 || value > 1000005) return -1;
    if (value == 1) return 0;
    usz limit = value.usz();
    bool* is_prime = (bool*)malloc(limit + 1);
    if (is_prime == null) return -2;
    defer free(is_prime);
    for (usz i = 0; i <= limit; i++) is_prime[i] = true;
    is_prime[0] = false;
    is_prime[1] = false;
    for (usz prime = 2; prime <= limit / prime; prime++) {
        if (!is_prime[prime]) continue;
        for (usz multiple = prime * prime; multiple <= limit; multiple += prime)
            is_prime[multiple] = false;
    }

    u32[10] primes;
    u32[10] exponents;
    usz count = 0;
    long remaining = value;
    for (usz prime = 2; prime <= limit && remaining > 1; prime++) {
        if (!is_prime[prime]) continue;
        u32 exponent = 0;
        while (remaining % prime.long() == 0) {
            remaining /= prime.long();
            exponent++;
        }
        if (exponent != 0) {
            primes[count] = prime.u32();
            exponents[count++] = exponent;
        }
    }
    usz required = count * 8;
    if (output == null || output_capacity < required) return -2;
    for (usz i = 0; i < count; i++) {
        write_u32le(primes[i], output, 8 * i);
        write_u32le(exponents[i], output, 8 * i + 4);
    }
    return required.long();
}
