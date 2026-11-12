module pow_of_formal_power_series;

const long MODULUS = 998244353;
const long MAX_EXPONENT = 1000000000000000000;
const usz MAX_N = 32;
const usz MAX_INPUT = 34;

fn void multiply_truncated(long* left, long* right, usz n, long* product) {
    for (usz i = 0; i < n; i++) product[i] = 0;
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n - i; j++)
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
}

fn void copy_poly(long* destination, long* source, usz n) {
    for (usz i = 0; i < n; i++) destination[i] = source[i];
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long pow_of_formal_power_series(long* input, usz length, uint8* output, usz capacity)
    @export("pow_of_formal_power_series") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long n_value = input[0];
    long exponent = input[1];
    if (n_value < 1 || n_value > (long)MAX_N || exponent < 0 || exponent > MAX_EXPONENT) return -1;
    usz n = (usz)n_value;
    if (length != n + 2) return -1;
    for (usz i = 0; i < n; i++)
        if (input[i + 2] < 0 || input[i + 2] >= MODULUS) return -1;

    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;
    long[MAX_N] result = {0};
    long[MAX_N] base = {0};
    long[MAX_N] temporary = {0};
    result[0] = 1;
    for (usz i = 0; i < n; i++) base[i] = input[i + 2];
    while (exponent > 0) {
        if ((exponent & 1) != 0) {
            multiply_truncated(&result[0], &base[0], n, &temporary[0]);
            copy_poly(&result[0], &temporary[0], n);
        }
        exponent >>= 1;
        if (exponent > 0) {
            multiply_truncated(&base[0], &base[0], n, &temporary[0]);
            copy_poly(&base[0], &temporary[0], n);
        }
    }
    for (usz i = 0; i < n; i++) store_le(output, 8 * i, result[i]);
    return (long)bytes;
}
