module tsvc_s452_index_weighted_vector_map;

const usz MAX_N = 64;
const usz MAX_INPUT_LENGTH = 1 + 2 * MAX_N;
const long MAX_VALUE = 2;

fn bool bounded_value(long value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s452_index_weighted_vector_map(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s452_index_weighted_vector_map") {
    if (input == null || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 1 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    if (length != 1 + 2 * n) return -1;

    usz b_start = 1, c_start = b_start + n;
    for (usz i = 0; i < n; i += 1) {
        if (!bounded_value(input[b_start + i]) || !bounded_value(input[c_start + i])) return -1;
    }
    if (output == null || output_capacity < 8 * n) return -2;

    for (usz i = 0; i < n; i += 1) {
        long index_weight = (long)(i + 1);
        long value = input[b_start + i] + input[c_start + i] * index_weight;
        store_i64_le(output, 8 * i, value);
    }
    return (long)n;
}
