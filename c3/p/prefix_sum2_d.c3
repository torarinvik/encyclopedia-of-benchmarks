module prefix_sum2_d;

const usz MAX_DIMENSION = 16;
const long INVALID_RESULT = (-9223372036854775807 - 1);

fn long prefix_sum2_d(long* input, usz length) @export("prefix_sum2_d") {
    if (input == null || length < 7) return INVALID_RESULT;
    long raw_rows = input[0], raw_cols = input[1];
    if (raw_rows < 1 || raw_rows > (long)MAX_DIMENSION || raw_cols < 1 || raw_cols > (long)MAX_DIMENSION) return INVALID_RESULT;
    usz rows = (usz)raw_rows, cols = (usz)raw_cols;
    if (length != 2 + rows * cols + 4) return INVALID_RESULT;
    usz query = 2 + rows * cols;
    long row1v = input[query], col1v = input[query + 1], row2v = input[query + 2], col2v = input[query + 3];
    if (row1v < 0 || col1v < 0 || row2v < row1v || col2v < col1v ||
        (ulong)row2v >= rows || (ulong)col2v >= cols) return INVALID_RESULT;
    long prefix[289] = {0};
    for (usz i = 0; i < rows; i++) {
        for (usz j = 0; j < cols; j++) {
            long value = input[2 + i * cols + j];
            if (value < -1000 || value > 1000) return INVALID_RESULT;
            usz at = (i + 1) * 17 + j + 1;
            prefix[at] = value + prefix[i * 17 + j + 1] + prefix[(i + 1) * 17 + j] - prefix[i * 17 + j];
        }
    }
    usz row1 = (usz)row1v, col1 = (usz)col1v, row2 = (usz)row2v, col2 = (usz)col2v;
    return prefix[(row2 + 1) * 17 + col2 + 1] - prefix[row1 * 17 + col2 + 1] -
        prefix[(row2 + 1) * 17 + col1] + prefix[row1 * 17 + col1];
}
