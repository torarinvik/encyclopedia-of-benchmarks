module composition_of_formal_power_series;

const long MODULUS = 998244353;
const usz MAX_N = 16;
const usz MAX_INPUT = 34;

fn void fps_store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long composition_of_formal_power_series(long* input, usz length,
                                            uint8* output, usz capacity)
    @export("composition_of_formal_power_series") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    if (n_value < 1 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    if (length != 1 + 2 * n) return -1;
    for (usz i = 0; i < 2 * n; i++) if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1 + n] != 0) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;

    long[MAX_N] composed = {0};
    for (usz outer = n; outer > 0; outer--) {
        for (usz bound = n; bound > 1; bound--) {
            usz degree = bound - 1;
            long sum = 0;
            for (usz inner_degree = 1; inner_degree <= degree; inner_degree++)
                sum = (sum + composed[degree - inner_degree] * input[1 + n + inner_degree]) % MODULUS;
            composed[degree] = sum;
        }
        composed[0] = input[outer];
    }
    for (usz i = 0; i < n; i++) fps_store_le(output, 8 * i, composed[i]);
    return (long)bytes;
}
