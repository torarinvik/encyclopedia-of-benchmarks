module polynomial_interpolation;

const long MODULUS = 998244353;
const usz MAX_N = 12;
const usz MAX_INPUT = 25;

fn long normalize(long value) {
    value %= MODULUS;
    if (value < 0) value += MODULUS;
    return value;
}

fn long power_mod(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent >>= 1;
    }
    return result;
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long polynomial_interpolation(long* input, usz length, uint8* output, usz capacity)
    @export("polynomial_interpolation") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 2 * n) return -1;
    for (usz i = 0; i < n; i++) {
        long xi = input[1 + i];
        long yi = input[1 + n + i];
        if (xi < 0 || xi >= MODULUS || yi < 0 || yi >= MODULUS) return -1;
        for (usz j = 0; j < i; j++) if (xi == input[1 + j]) return -1;
    }

    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    long[MAX_N] result = {0};
    for (usz i = 0; i < n; i++) {
        long[MAX_N + 1] basis = {0};
        basis[0] = 1;
        usz degree = 0;
        long denominator = 1;
        for (usz j = 0; j < n; j++) {
            if (j == i) continue;
            long xj = input[1 + j];
            denominator = denominator * (input[1 + i] - xj) % MODULUS;
            long[MAX_N + 1] expanded = {0};
            for (usz k = 0; k <= degree; k++) {
                expanded[k] = normalize(expanded[k] - basis[k] * xj);
                expanded[k + 1] = normalize(expanded[k + 1] + basis[k]);
            }
            for (usz k = 0; k <= degree + 1; k++) basis[k] = expanded[k];
            degree++;
        }
        long scale = input[1 + n + i] * power_mod(normalize(denominator), MODULUS - 2) % MODULUS;
        for (usz k = 0; k < n; k++) result[k] = (result[k] + scale * basis[k]) % MODULUS;
    }
    for (usz i = 0; i < n; i++) store_le(output, 8 * i, result[i]);
    return (long)bytes;
}
