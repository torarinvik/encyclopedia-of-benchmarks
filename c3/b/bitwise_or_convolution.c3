module bitwise_or_convolution;

const usz MAX_N = 8;
const usz MAX_SIZE = 1 << MAX_N;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_SIZE;
const long MODULUS = 998244353;

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long bitwise_or_convolution(long *input, usz length, char *output, usz capacity)
    @export("bitwise_or_convolution") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value, size = (usz)1 << n;
    if (length != 1 + 2 * size) return -1;
    for (usz i = 0; i < 2 * size; i++) if (input[1 + i] < 0 || input[1 + i] >= MODULUS) return -1;
    usz bytes = 8 * size;
    if (output == null || capacity < bytes) return -2;
    long[MAX_SIZE] a; long[MAX_SIZE] b;
    for (usz i = 0; i < MAX_SIZE; i++) { a[i] = 0; b[i] = 0; }
    for (usz i = 0; i < size; i++) { a[i] = input[1 + i]; b[i] = input[1 + size + i]; }
    for (usz bit = 0; bit < n; bit++) {
        usz bit_mask = (usz)1 << bit;
        for (usz mask = 0; mask < size; mask++) if ((mask & bit_mask) != 0) {
            a[mask] = (a[mask] + a[mask ^ bit_mask]) % MODULUS;
            b[mask] = (b[mask] + b[mask ^ bit_mask]) % MODULUS;
        }
    }
    for (usz i = 0; i < size; i++) a[i] = (a[i] * b[i]) % MODULUS;
    for (usz bit = 0; bit < n; bit++) {
        usz bit_mask = (usz)1 << bit;
        for (usz mask = 0; mask < size; mask++) if ((mask & bit_mask) != 0) {
            a[mask] -= a[mask ^ bit_mask];
            if (a[mask] < 0) a[mask] += MODULUS;
        }
    }
    for (usz i = 0; i < size; i++) store_i64_le(output, 8 * i, a[i]);
    return (long)bytes;
}
