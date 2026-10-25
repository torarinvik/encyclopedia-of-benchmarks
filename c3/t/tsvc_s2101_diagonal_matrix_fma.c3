module tsvc_s2101_diagonal_matrix_fma;

const usz MAX_N = 8;
const usz MAX_CELLS = MAX_N * MAX_N;
const usz MAX_INPUT_LENGTH = 1 + 3 * MAX_CELLS;
const long MAX_VALUE = 100;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1)
        output[offset + byte] = (char)((bits >> (8 * byte)) & 255);
}

fn long tsvc_s2101_diagonal_matrix_fma_impl(long* input, usz length,
        char* output, usz output_capacity) {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long n_raw = input[0];
    if (n_raw < 1 || n_raw > (long)MAX_N) return -1;
    usz n = (usz)n_raw;
    usz cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    for (usz i = 0; i < 3 * cells; i += 1) {
        long value = input[i + 1];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
    }
    if (output == null || output_capacity < 8 * cells) return -2;

    for (usz cell = 0; cell < cells; cell += 1)
        store_i64_le(output, 8 * cell, input[cell + 1]);
    for (usz i = 0; i < n; i += 1) {
        usz diagonal = i * n + i;
        long value = input[1 + diagonal] +
            input[1 + cells + diagonal] * input[1 + 2 * cells + diagonal];
        store_i64_le(output, 8 * diagonal, value);
    }
    return (long)cells;
}

fn long tsvc_s2101_diagonal_matrix_fma(long* input, usz length,
        char* output, usz output_capacity) @export("tsvc_s2101_diagonal_matrix_fma") {
    return tsvc_s2101_diagonal_matrix_fma_impl(input, length, output, output_capacity);
}
