module compositional_inverse_of_formal_power_series;

const long MODULUS = 998244353;
const usz MIN_N = 2;
const usz MAX_N = 16;
const usz MAX_INPUT = 18;

fn long fps_mod_pow(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent /= 2;
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

fn long compositional_inverse_of_formal_power_series(long* input, usz length,
    uint8* output, usz capacity) @export("compositional_inverse_of_formal_power_series") {
    if (input == null || length < MIN_N + 1 || length > MAX_INPUT) return -1;
    if (input[0] < (long)MIN_N || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1] != 0 || input[2] == 0) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;

    long[MAX_N * MAX_N] powers = {0};
    long[MAX_N] inverse_series = {0};
    long inverse_linear = fps_mod_pow(input[2], MODULUS - 2);
    inverse_series[1] = inverse_linear;
    powers[MAX_N + 1] = inverse_linear;
    for (usz degree = 2; degree < n; degree++) {
        for (usz power = 2; power <= degree; power++) {
            long coefficient = 0;
            for (usz split = 1; split < degree; split++)
                coefficient = (coefficient + powers[(power - 1) * MAX_N + degree - split] * inverse_series[split]) % MODULUS;
            powers[power * MAX_N + degree] = coefficient;
        }
        long composed_coefficient = 0;
        for (usz power = 2; power <= degree; power++)
            composed_coefficient = (composed_coefficient + input[power + 1] * powers[power * MAX_N + degree]) % MODULUS;
        inverse_series[degree] = (MODULUS - composed_coefficient) * inverse_linear % MODULUS;
        powers[MAX_N + degree] = inverse_series[degree];
    }
    for (usz i = 0; i < n; i++) fps_store_le(output, 8 * i, inverse_series[i]);
    return (long)bytes;
}
