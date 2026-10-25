module tsvc_s343_column_major_compaction;

const usz MAX_ROWS = 8;
const usz MAX_COLS = 8;
const usz MAX_CELLS = MAX_ROWS * MAX_COLS;
const usz MAX_INPUT_LENGTH = 2 + 2 * MAX_CELLS;
const usz BYTES_PER_VALUE = 8;

fn void store_i64_le(char* output, usz position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < BYTES_PER_VALUE; byte += 1)
        output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

fn long tsvc_s343_column_major_compaction(long* input, usz length,
        char* output, usz output_capacity) @export("tsvc_s343_column_major_compaction") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long rows_raw = input[0], cols_raw = input[1];
    if (rows_raw < 1 || rows_raw > (long)MAX_ROWS ||
        cols_raw < 1 || cols_raw > (long)MAX_COLS) return -1;
    usz rows = (usz)rows_raw, cols = (usz)cols_raw;
    usz cells = rows * cols;
    if (length != 2 + 2 * cells) return -1;
    if (output == null || output_capacity < cells * BYTES_PER_VALUE) return -2;

    usz data_start = 2, mask_start = data_start + cells;
    usz written = 0;
    for (usz col = 0; col < cols; col += 1) {
        for (usz row = 0; row < rows; row += 1) {
            usz index = row * cols + col;
            if (input[mask_start + index] > 0) {
                store_i64_le(output, written * BYTES_PER_VALUE, input[data_start + index]);
                written += 1;
            }
        }
    }
    return (long)written;
}
