module newton_inverse_sqrt_fps;

const long MODULUS = 998244353;
const long HALF = 499122177;

fn void multiply(long* left, long* right, usz width, long* result) {
    for (usz i = 0; i < width; i++) result[i] = 0;
    for (usz i = 0; i < width; i++)
        for (usz j = 0; i + j < width; j++)
            result[i + j] = (result[i + j] + left[i] * right[j]) % MODULUS;
}

fn long newton_inverse_sqrt_fps(long* input, usz length, uint8* output, usz capacity)
    @export("newton_inverse_sqrt_fps") {
    if (input == null || length < 2 || length > 66) return -1;
    if (input[0] < 1 || input[0] > 64) return -1;
    usz n = (usz)input[0];
    if (length != n + 1) return -1;
    for (usz i = 0; i < n; i++) if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1] != 1) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    long[64] f = zeroed, inverse = zeroed, square = zeroed;
    long[64] product = zeroed, correction = zeroed, next = zeroed;
    for (usz i = 0; i < n; i++) f[i] = input[i + 1];
    inverse[0] = 1;
    usz precision = 1;
    while (precision < n) {
        usz width = 2 * precision < n ? 2 * precision : n;
        multiply(&inverse[0], &inverse[0], width, &square[0]);
        multiply(&f[0], &square[0], width, &product[0]);
        correction[0] = (3 + MODULUS - product[0]) * HALF % MODULUS;
        for (usz i = 1; i < width; i++) correction[i] = (MODULUS - product[i]) * HALF % MODULUS;
        multiply(&inverse[0], &correction[0], width, &next[0]);
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
