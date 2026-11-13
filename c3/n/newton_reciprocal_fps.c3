module newton_reciprocal_fps;

const long MODULUS = 998244353;

fn long power(long base, long exponent) {
    long result = 1;
    while (exponent > 0) {
        if (exponent % 2 != 0) result = result * base % MODULUS;
        base = base * base % MODULUS;
        exponent /= 2;
    }
    return result;
}

fn long newton_reciprocal_fps(long* input, usz length, uint8* output, usz capacity)
    @export("newton_reciprocal_fps") {
    if (input == null || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > 64) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1] == 0) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    long[64] inverse = zeroed, correction = zeroed, next = zeroed;
    inverse[0] = power(input[1], MODULUS - 2);
    usz precision = 1;
    while (precision < n) {
        usz width = 2 * precision < n ? 2 * precision : n;
        for (usz i = 0; i < width; i++) correction[i] = 0;
        for (usz i = 0; i < width; i++)
            for (usz j = 0; j < precision && i + j < width; j++)
                correction[i + j] = (correction[i + j] + input[i + 1] * inverse[j]) % MODULUS;
        correction[0] = (2 + MODULUS - correction[0]) % MODULUS;
        for (usz i = 1; i < width; i++) correction[i] = (MODULUS - correction[i]) % MODULUS;
        for (usz i = 0; i < width; i++) next[i] = 0;
        for (usz i = 0; i < precision; i++)
            for (usz j = 0; i + j < width; j++)
                next[i + j] = (next[i + j] + inverse[i] * correction[j]) % MODULUS;
        for (usz i = 0; i < width; i++) inverse[i] = next[i];
        precision = width;
    }
    for (usz i = 0; i < n; i++) {
        ulong bits = (ulong)inverse[i];
        for (usz byte = 0; byte < 8; byte++) {
            output[8 * i + byte] = (uint8)(bits & 255ul);
            bits >>= 8;
        }
    }
    return (long)bytes;
}
