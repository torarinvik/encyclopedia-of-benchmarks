module tsvc_s319_coupled_reductions;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + 3 * MAX_N;
const long MAX_VALUE = 2;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s319_coupled_reductions(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s319_coupled_reductions") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 1 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + 3 * n) return -1;

    usz c_start = 1, d_start = c_start + n, e_start = d_start + n;
    for (usz i = 0; i < n; i += 1) {
        if (input[c_start + i] < -MAX_VALUE || input[c_start + i] > MAX_VALUE ||
            input[d_start + i] < -MAX_VALUE || input[d_start + i] > MAX_VALUE ||
            input[e_start + i] < -MAX_VALUE || input[e_start + i] > MAX_VALUE) return -1;
    }
    usz value_count = 2 * n + 1;
    if (output == null || output_capacity < 8 * value_count) return -2;

    long total = 0;
    for (usz i = 0; i < n; i += 1) {
        long a_value = input[c_start + i] + input[d_start + i];
        long b_value = input[c_start + i] + input[e_start + i];
        store_i64_le(output, 8 * i, a_value);
        store_i64_le(output, 8 * (n + i), b_value);
        total += a_value;
        total += b_value;
    }
    store_i64_le(output, 8 * (2 * n), total);
    return (long)value_count;
}
