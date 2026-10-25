// Clean-room port of TSVC s126; see package README for provenance and rights.
module tsvc_s126_matrix_column_recurrence;

const usz MAX_N = 6;
const usz MAX_CELLS = MAX_N * MAX_N;
const usz MAX_INPUT_LENGTH = 1 + 3 * MAX_CELLS;

fn void store_i64_le(uchar* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (uchar)(bits & 0xffu);
        bits >>= 8;
    }
}

long tsvc_s126_matrix_column_recurrence(long* input, usz length, uchar* output, usz capacity) @export("tsvc_s126_matrix_column_recurrence") {
    if (input == null || length < 13 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 2 || input[0] > (long)MAX_N) return -1;
    usz n = (usz)input[0];
    usz cells = n * n;
    if (length != 1 + 3 * cells) return -1;
    long[MAX_CELLS] coefficients, c_matrix, b_matrix;
    for (usz i = 0; i < cells; i++) {
        coefficients[i] = input[1 + i];
        c_matrix[i] = input[1 + cells + i];
        b_matrix[i] = input[1 + 2 * cells + i];
        if (coefficients[i] < -100 || coefficients[i] > 100 ||
            c_matrix[i] < -100 || c_matrix[i] > 100 || b_matrix[i] < -100 || b_matrix[i] > 100) return -1;
    }
    usz output_bytes = 8 * cells;
    if (output == null || capacity < output_bytes) return -2;
    usz k = 1;
    for (usz i = 0; i < n; i++) {
        for (usz j = 1; j < n; j++) {
            usz target = j * n + i;
            b_matrix[target] = b_matrix[target - n] + coefficients[k - 1] * c_matrix[target];
            k++;
        }
        k++;
    }
    for (usz i = 0; i < cells; i++) store_i64_le(output, 8 * i, b_matrix[i]);
    return (long)cells;
}
