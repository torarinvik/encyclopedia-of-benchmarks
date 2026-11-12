module polynomial_taylor_shift;

const long MODULUS = 998244353;
const usz MAX_N = 64;
const usz MAX_INPUT = 66;

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long polynomial_taylor_shift(long* input, usz length, uint8* output, usz capacity)
    @export("polynomial_taylor_shift") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    long shift = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || length != 2 + (usz)n_value) return -1;
    if (shift < 0 || shift >= MODULUS) return -1;
    usz n = (usz)n_value;
    for (usz i = 0; i < n; i++)
        if (input[i + 2] < 0 || input[i + 2] >= MODULUS) return -1;

    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    long[MAX_N] shifted = {0};
    usz processed = 0;
    for (usz source = n; source > 0; source--) {
        for (usz degree = processed; degree > 0; degree--)
            shifted[degree] = (shifted[degree] * shift + shifted[degree - 1]) % MODULUS;
        shifted[0] = (shifted[0] * shift + input[source + 1]) % MODULUS;
        processed++;
    }
    for (usz i = 0; i < n; i++) store_le(output, 8 * i, shifted[i]);
    return (long)bytes;
}
