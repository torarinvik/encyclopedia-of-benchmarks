module tsvc_s141_packed_symmetric_update;

const usz MAX_N = 16;
const usz MAX_TRIANGLE = MAX_N * (MAX_N + 1) / 2;
const usz MAX_INPUT_LENGTH = 2 + MAX_TRIANGLE + MAX_N * MAX_N;
const long MAX_VALUE = 1000000;
const usz MAX_ROUNDS = 32;

fn bool bounded_value(long value) {
    return value >= -MAX_VALUE && value <= MAX_VALUE;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s141_packed_symmetric_update(long* input, usz length, char* output,
        usz output_capacity) @export("tsvc_s141_packed_symmetric_update") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0], rounds_raw = input[1];
    if (n_raw < 1 || n_raw > (long)MAX_N || rounds_raw < 1 || rounds_raw > (long)MAX_ROUNDS) return -1;
    usz n = (usz)n_raw;
    usz triangle = n * (n + 1) / 2;
    usz matrix_start = 2 + triangle;
    if (length != matrix_start + n * n) return -1;

    long[MAX_TRIANGLE] packed;
    for (usz p = 0; p < triangle; p += 1) {
        packed[p] = input[2 + p];
        if (!bounded_value(packed[p])) return -1;
    }
    for (usz p = 0; p < n * n; p += 1)
        if (!bounded_value(input[matrix_start + p])) return -1;
    if (output == null || output_capacity < 8 * triangle) return -2;

    for (usz round = 0; round < (usz)rounds_raw; round += 1) {
        for (usz i = 0; i < n; i += 1) {
            for (usz j = i; j < n; j += 1) {
                usz k = j * (j + 1) / 2 + i;
                packed[k] += input[matrix_start + j * n + i];
            }
        }
    }
    for (usz p = 0; p < triangle; p += 1) store_i64_le(output, 8 * p, packed[p]);
    return (long)triangle;
}
