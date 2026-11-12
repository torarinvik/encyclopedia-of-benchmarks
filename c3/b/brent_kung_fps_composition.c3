module brent_kung_fps_composition;

const long MODULUS = 998244353L;
const usz MAX_N = 32;
const usz MAX_INPUT = 66;
const usz MAX_BLOCKS = 6;
const usz MAX_POWERS = 7;

fn void multiply_truncated(long* left, long* right, long* product, usz n) {
    for (usz degree = 0; degree < n; degree++) product[degree] = 0;
    for (usz i = 0; i < n; i++)
        for (usz j = 0; j < n - i; j++)
            product[i + j] = (product[i + j] + left[i] * right[j]) % MODULUS;
}

fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uint8)(bits & 255ul);
        bits >>= 8;
    }
}

fn long brent_kung_fps_composition(long* input, usz length,
                                    uint8* output, usz capacity)
    @export("brent_kung_fps_composition") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 2 * n) return -1;
    for (usz i = 0; i < 2 * n; i++)
        if (input[i + 1] < 0 || input[i + 1] >= MODULUS) return -1;
    if (input[1 + n] != 0) return -1;
    usz bytes = 8 * n;
    if (output == null || capacity < bytes) return -2;

    usz block_size = 1;
    while (block_size * block_size < n) block_size++;
    usz block_count = (n + block_size - 1) / block_size;
    long[MAX_POWERS * MAX_N] powers = {};
    long[MAX_BLOCKS * MAX_N] blocks = {};
    long[MAX_N] temporary = {};
    long[MAX_N] composed = {};
    powers[0] = 1;
    for (usz exponent = 1; exponent <= block_size; exponent++) {
        multiply_truncated(&powers[(exponent - 1) * MAX_N], &input[1 + n],
                           &temporary[0], n);
        for (usz degree = 0; degree < n; degree++)
            powers[exponent * MAX_N + degree] = temporary[degree];
    }
    for (usz block = 0; block < block_count; block++) {
        for (usz offset = 0; offset < block_size; offset++) {
            usz coefficient_index = block * block_size + offset;
            if (coefficient_index >= n) break;
            long coefficient = input[1 + coefficient_index];
            for (usz degree = 0; degree < n; degree++) {
                usz block_index = block * MAX_N + degree;
                blocks[block_index] =
                    (blocks[block_index] + coefficient * powers[offset * MAX_N + degree]) % MODULUS;
            }
        }
    }
    for (usz degree = 0; degree < n; degree++)
        composed[degree] = blocks[(block_count - 1) * MAX_N + degree];
    for (usz block = block_count - 1; block > 0; block--) {
        multiply_truncated(&composed[0], &powers[block_size * MAX_N], &temporary[0], n);
        for (usz degree = 0; degree < n; degree++)
            composed[degree] = (temporary[degree] + blocks[(block - 1) * MAX_N + degree]) % MODULUS;
    }
    for (usz degree = 0; degree < n; degree++) store_le(output, 8 * degree, composed[degree]);
    return (long)bytes;
}
