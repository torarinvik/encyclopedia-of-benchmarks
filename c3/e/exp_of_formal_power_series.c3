module exp_of_formal_power_series;

const long MODULUS = 998244353;
const usz MAX_N = 64;
const usz MAX_INPUT = 66;

fn void fps_store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long exp_of_formal_power_series(long* input, usz length,
                                  uint8* output, usz capacity)
    @export("exp_of_formal_power_series") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1] != 0) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;

    long[MAX_N] integer_inverse = {0};
    long[MAX_N] exponential = {0};
    if (n > 1) integer_inverse[1] = 1;
    for (usz k = 2; k < n; k++)
        integer_inverse[k] = MODULUS - (MODULUS / (long)k) * integer_inverse[(usz)(MODULUS % (long)k)] % MODULUS;
    exponential[0] = 1;
    for (usz degree = 1; degree < n; degree++) {
        long sum = 0;
        for (usz i = 1; i <= degree; i++) {
            long term = ((long)i * input[i + 1]) % MODULUS;
            term = term * exponential[degree - i] % MODULUS;
            sum = (sum + term) % MODULUS;
        }
        exponential[degree] = sum * integer_inverse[degree] % MODULUS;
    }
    for (usz i = 0; i < n; i++) fps_store_le(output, 8 * i, exponential[i]);
    return (long)bytes;
}
