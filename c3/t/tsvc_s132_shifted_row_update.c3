module tsvc_s132_shifted_row_update;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 2 + 3 * MAX_N;
const long MAX_VALUE = 1000000;

fn bool bounded_value(long value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s132_shifted_row_update(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s132_shifted_row_update") {
    if (input == null || length < 8 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 2 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 2 + 3 * n) return -1;

    usz row_start = 1;
    usz target_start = row_start + n;
    usz b_start = target_start + n;
    usz c1_index = b_start + n;
    long[MAX_N] target;
    for (usz i = 0; i < n; i += 1) {
        target[i] = input[target_start + i];
        if (!bounded_value(input[row_start + i]) || !bounded_value(target[i]) ||
            !bounded_value(input[b_start + i])) return -1;
    }
    long c1 = input[c1_index];
    if (!bounded_value(c1)) return -1;
    if (output == null || output_capacity < 8 * n) return -2;

    for (usz i = 1; i < n; i += 1)
        target[i] = input[row_start + i - 1] + input[b_start + i] * c1;
    for (usz i = 0; i < n; i += 1) store_i64_le(output, 8 * i, target[i]);
    return (long)n;
}
