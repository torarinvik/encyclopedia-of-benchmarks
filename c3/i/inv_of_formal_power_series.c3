module inv_of_formal_power_series;

const long MODULUS = 998244353;
const usz MAX_N = 64;
const usz MAX_INPUT = 66;

fn long fps_pow_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void fps_store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long inv_of_formal_power_series(long* input, usz length,
                                   uint8* output, usz capacity)
    @export("inv_of_formal_power_series") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1] == 0) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;

    long[MAX_N] inverse = {0};
    long inverse_constant = fps_pow_mod(input[1], MODULUS - 2);
    inverse[0] = inverse_constant;
    for (usz degree = 1; degree < n; degree++) {
        long sum = 0;
        for (usz i = 1; i <= degree; i++) sum = (sum + input[i + 1] * inverse[degree - i]) % MODULUS;
        inverse[degree] = (MODULUS - inverse_constant * sum % MODULUS) % MODULUS;
    }
    for (usz i = 0; i < n; i++) fps_store_le(output, 8 * i, inverse[i]);
    return (long)bytes;
}
