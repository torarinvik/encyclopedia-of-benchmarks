module bitwise_and_convolution;

const usz MAX_N = 8;
const usz MAX_SIZE = 1 << MAX_N;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_SIZE;
const long MODULUS = 998244353;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long bitwise_and_convolution(long* input, usz length, char* output,
    usz capacity) @export("bitwise_and_convolution") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    usz size = (usz)1 << n;
    if (length != 1 + 2 * size) return -1;
    for (usz index = 0; index < 2 * size; index += 1)
        if (input[1 + index] < 0 || input[1 + index] >= MODULUS) return -1;
    usz output_bytes = 8 * size;
    if (output == null || capacity < output_bytes) return -2;

    long[MAX_SIZE] a;
    long[MAX_SIZE] b;
    for (usz index = 0; index < MAX_SIZE; index += 1) { a[index] = 0; b[index] = 0; }
    for (usz index = 0; index < size; index += 1) {
        a[index] = input[1 + index];
        b[index] = input[1 + size + index];
    }
    for (usz bit = 0; bit < n; bit += 1) {
        usz bit_mask = (usz)1 << bit;
        for (usz mask = 0; mask < size; mask += 1) {
            if ((mask & bit_mask) == 0) {
                a[mask] = (a[mask] + a[mask | bit_mask]) % MODULUS;
                b[mask] = (b[mask] + b[mask | bit_mask]) % MODULUS;
            }
        }
    }
    for (usz mask = 0; mask < size; mask += 1) a[mask] = (a[mask] * b[mask]) % MODULUS;
    for (usz bit = 0; bit < n; bit += 1) {
        usz bit_mask = (usz)1 << bit;
        for (usz mask = 0; mask < size; mask += 1) {
            if ((mask & bit_mask) == 0) {
                a[mask] -= a[mask | bit_mask];
                if (a[mask] < 0) a[mask] += MODULUS;
            }
        }
    }
    for (usz mask = 0; mask < size; mask += 1) store_i64_le(output, 8 * mask, a[mask]);
    return (long)output_bytes;
}
