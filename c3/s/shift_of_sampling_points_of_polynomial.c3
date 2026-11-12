module shift_of_sampling_points_of_polynomial;

const long MODULUS = 998244353;
const usz MAX_N = 16;
const usz MAX_M = 16;
const usz MAX_INPUT = 20;

fn long mod_pow(long base, long exponent) {
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

fn long shift_of_sampling_points_of_polynomial(long* input, usz length,
                                                uint8* output, usz capacity)
    @export("shift_of_sampling_points_of_polynomial") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 1 || input[1] > (long)MAX_M) return -1;
    usz n = (usz)input[0];
    usz m = (usz)input[1];
    long start = input[2];
    if (length != n + 3 || start < 0 || start >= MODULUS) return -1;
    for (usz i = 0; i < n; i++)
        if (input[i + 3] < 0 || input[i + 3] >= MODULUS) return -1;

    usz bytes = 8 * m;
    if (output == null || capacity < bytes) return -2;
    long[MAX_N] differences = {};
    long[MAX_N] newton = {};
    long[MAX_N] factorial = {};
    long[MAX_N] inverse_factorial = {};
    for (usz i = 0; i < n; i++) differences[i] = input[i + 3];
    factorial[0] = 1;
    for (usz k = 1; k < n; k++) factorial[k] = factorial[k - 1] * (long)k % MODULUS;
    inverse_factorial[n - 1] = mod_pow(factorial[n - 1], MODULUS - 2);
    for (usz k = n - 1; k > 0; k--) inverse_factorial[k - 1] = inverse_factorial[k] * (long)k % MODULUS;
    for (usz k = 0; k < n; k++) {
        newton[k] = differences[0] * inverse_factorial[k] % MODULUS;
        for (usz i = 0; i + k + 1 < n; i++) {
            differences[i] = differences[i + 1] - differences[i];
            if (differences[i] < 0) differences[i] += MODULUS;
        }
    }
    for (usz offset = 0; offset < m; offset++) {
        long x = start + (long)offset;
        if (x >= MODULUS) x -= MODULUS;
        long basis = 1;
        long value = 0;
        for (usz k = 0; k < n; k++) {
            value = (value + newton[k] * basis) % MODULUS;
            long factor = x - (long)k;
            if (factor < 0) factor += MODULUS;
            basis = basis * factor % MODULUS;
        }
        store_le(output, 8 * offset, value);
    }
    return (long)bytes;
}
