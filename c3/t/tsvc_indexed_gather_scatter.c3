module tsvc_indexed_gather_scatter;

const usz MAX_N = 16;
const usz MAX_INPUT_LENGTH = 2 + 5 * MAX_N;
const long MAX_OPERAND = 1000000;

fn bool bounded_operand(long value) {
    return value >= -MAX_OPERAND && value <= MAX_OPERAND;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_indexed_gather_scatter(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_indexed_gather_scatter") {
    if (input == null || length < 6 || length > MAX_INPUT_LENGTH) return -1;
    long mode = input[0], n_raw = input[1];
    if ((mode != 491 && mode != 4113) || n_raw < 1 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 2 + (mode == 491 ? 5 : 4) * n) return -1;

    usz index_start = 2, a_start = index_start + n;
    usz b_start = a_start + n, c_start = b_start + n, d_start = c_start + n;
    long[MAX_N] state;
    for (usz i = 0; i < n; i += 1) {
        long index = input[index_start + i];
        if (index < 0 || index >= n_raw) return -1;
        state[i] = input[a_start + i];
        if (!bounded_operand(input[b_start + i]) || !bounded_operand(input[c_start + i])) return -1;
        if (mode == 491 && !bounded_operand(input[d_start + i])) return -1;
    }
    if (output == null || output_capacity < 8 * n) return -2;

    for (usz i = 0; i < n; i += 1) {
        usz index = (usz)input[index_start + i];
        if (mode == 491)
            state[index] = input[b_start + i] + input[c_start + i] * input[d_start + i];
        else
            state[index] = input[b_start + index] + input[c_start + i];
    }
    for (usz i = 0; i < n; i += 1) store_i64_le(output, 8 * i, state[i]);
    return (long)n;
}
