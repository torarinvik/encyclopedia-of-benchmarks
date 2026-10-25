module tsvc_s241_cross_coupled_product_map;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + 4 * MAX_N;
const long MAX_VALUE = 2;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s241_cross_coupled_product_map(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s241_cross_coupled_product_map") {
    if (input == null || length < 9 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 2 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + 4 * n) return -1;

    usz a_start = 1, b_start = a_start + n;
    usz c_start = b_start + n, d_start = c_start + n;
    long[MAX_N] a, b;
    for (usz i = 0; i < n; i += 1) {
        a[i] = input[a_start + i];
        b[i] = input[b_start + i];
        if (a[i] < -MAX_VALUE || a[i] > MAX_VALUE ||
            b[i] < -MAX_VALUE || b[i] > MAX_VALUE ||
            input[c_start + i] < -MAX_VALUE || input[c_start + i] > MAX_VALUE ||
            input[d_start + i] < -MAX_VALUE || input[d_start + i] > MAX_VALUE) return -1;
    }
    if (output == null || output_capacity < 16 * n) return -2;

    for (usz i = 0; i + 1 < n; i += 1) {
        long next_a = a[i + 1];
        a[i] = b[i] * input[c_start + i] * input[d_start + i];
        b[i] = a[i] * next_a * input[d_start + i];
    }
    for (usz i = 0; i < n; i += 1) {
        store_i64_le(output, 8 * i, a[i]);
        store_i64_le(output, 8 * (n + i), b[i]);
    }
    return (long)(2 * n);
}
