module newton_compositional_inverse_fps;

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

fn void compose(long* outer, long* inner, usz width, long* result) {
    long[16] scratch = zeroed;
    for (usz i = 0; i < width; i++) result[i] = 0;
    usz degree = width;
    while (degree > 0) {
        degree--;
        for (usz i = 0; i < width; i++) scratch[i] = 0;
        for (usz i = 0; i < width; i++)
            for (usz j = 0; j < width - i; j++)
                scratch[i + j] = (scratch[i + j] + result[i] * inner[j]) % MODULUS;
        scratch[0] = (scratch[0] + outer[degree]) % MODULUS;
        for (usz i = 0; i < width; i++) result[i] = scratch[i];
    }
}

fn long newton_compositional_inverse_fps(long* input, usz length, uint8* output, usz capacity)
    @export("newton_compositional_inverse_fps") {
    if (input == null || length < 3 || length > 18) return -1;
    if (input[0] < 2 || input[0] > 16) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1] != 0 || input[2] == 0) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    long[16] f = zeroed, derivative = zeroed, inverse = zeroed;
    long[16] residual = zeroed, slope = zeroed, reciprocal = zeroed, correction = zeroed;
    for (usz i = 0; i < n; i++) f[i] = input[i + 1];
    for (usz i = 1; i < n; i++) derivative[i - 1] = (long)i * f[i] % MODULUS;
    long inverse_linear = power(f[1], MODULUS - 2);
    inverse[1] = inverse_linear;
    usz precision = 2;
    while (precision < n) {
        usz width = precision * 2 < n ? precision * 2 : n;
        compose(&f[0], &inverse[0], width, &residual[0]);
        residual[1] = (residual[1] + MODULUS - 1) % MODULUS;
        compose(&derivative[0], &inverse[0], width, &slope[0]);
        reciprocal[0] = inverse_linear;
        for (usz i = 1; i < width; i++) {
            long sum = 0;
            for (usz j = 1; j <= i; j++) sum = (sum + slope[j] * reciprocal[i - j]) % MODULUS;
            reciprocal[i] = (MODULUS - sum) * inverse_linear % MODULUS;
        }
        for (usz i = 0; i < width; i++) {
            correction[i] = 0;
            for (usz j = 0; j <= i; j++)
                correction[i] = (correction[i] + residual[j] * reciprocal[i - j]) % MODULUS;
        }
        for (usz i = 0; i < width; i++) inverse[i] = (inverse[i] + MODULUS - correction[i]) % MODULUS;
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
