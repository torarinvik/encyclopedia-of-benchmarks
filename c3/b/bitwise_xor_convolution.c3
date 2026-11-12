module bitwise_xor_convolution;

const usz MAX_N = 8;
const usz MAX_SIZE = 1 << MAX_N;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_SIZE;
const long MODULUS = 998244353;

fn void xor_walsh_transform(long *values, usz size) {
    for (usz half = 1; half < size; half *= 2) {
        for (usz block = 0; block < size; block += 2 * half) {
            for (usz offset = 0; offset < half; offset++) {
                long left = values[block + offset];
                long right = values[block + half + offset];
                values[block + offset] = (left + right) % MODULUS;
                values[block + half + offset] = (left - right + MODULUS) % MODULUS;
            }
        }
    }
}

fn void store_i64_le(char *output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long bitwise_xor_convolution(long *input, usz length, char *output, usz capacity)
    @export("bitwise_xor_convolution") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0];
    if (n_value < 0 || n_value > (long)MAX_N) return -1;
    usz n = (usz)n_value;
    usz size = (usz)1 << n;
    if (length != 1 + 2 * size) return -1;
    for (usz index = 0; index < 2 * size; index++)
        if (input[1 + index] < 0 || input[1 + index] >= MODULUS) return -1;

    usz output_bytes = 8 * size;
    if (output == null || capacity < output_bytes) return -2;
    long[MAX_SIZE] first;
    long[MAX_SIZE] second;
    for (usz index = 0; index < MAX_SIZE; index++) { first[index] = 0; second[index] = 0; }
    for (usz index = 0; index < size; index++) {
        first[index] = input[1 + index];
        second[index] = input[1 + size + index];
    }
    xor_walsh_transform(&first[0], size);
    xor_walsh_transform(&second[0], size);
    for (usz index = 0; index < size; index++)
        first[index] = (first[index] * second[index]) % MODULUS;
    xor_walsh_transform(&first[0], size);

    long inverse_size = 1;
    for (usz bit = 0; bit < n; bit++) inverse_size = (inverse_size * ((MODULUS + 1) / 2)) % MODULUS;
    for (usz index = 0; index < size; index++)
        store_i64_le(output, 8 * index, (first[index] * inverse_size) % MODULUS);
    return (long)output_bytes;
}
