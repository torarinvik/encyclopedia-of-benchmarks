module blelloch_parallel_prefix_scan;

const usz MAX_ITEMS = 64;
const usz MAX_INPUT_WORDS = 66;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long blelloch_parallel_prefix_scan(long* input, usz length, char* output,
                                      usz output_capacity)
        @export("blelloch_parallel_prefix_scan") {
    if (input == null || length < 2 || length > MAX_INPUT_WORDS) return -1;
    long n64 = input[0];
    if (n64 < 1 || n64 > (long)MAX_ITEMS) return -1;
    usz n = (usz)n64;
    if (length != n + 1) return -1;

    long[MAX_ITEMS] tree = {0};
    usz padded = 1;
    while (padded < n) padded <<= 1;
    for (usz i = 0; i < n; i++) {
        long value = input[i + 1];
        if (value < -1000000 || value > 1000000) return -1;
        tree[i] = value;
    }
    if (output == null || output_capacity < n * 8) return -2;

    for (usz stride = 2; stride <= padded; stride <<= 1) {
        usz half = stride >> 1;
        for (usz right = stride - 1; right < padded; right += stride)
            tree[right] += tree[right - half];
    }
    tree[padded - 1] = 0;
    for (usz stride = padded; stride >= 2; stride >>= 1) {
        usz half = stride >> 1;
        for (usz right = stride - 1; right < padded; right += stride) {
            usz left = right - half;
            long partial = tree[left];
            tree[left] = tree[right];
            tree[right] += partial;
        }
    }
    for (usz i = 0; i < n; i++) store_i64_le(output, i * 8, tree[i]);
    return (long)(n * 8);
}
