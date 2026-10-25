#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 8
#define MAX_COLS 8
#define MAX_CELLS (MAX_ROWS * MAX_COLS)
#define MAX_INPUT_LENGTH (2 + 2 * MAX_CELLS)
#define BYTES_PER_VALUE 8

static void store_i64_le(uint8_t *output, size_t position, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t tsvc_s343_column_major_compaction(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t rows_raw = input[0], cols_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS || cols_raw < 1 || cols_raw > MAX_COLS) return -1;
    const size_t rows = (size_t)rows_raw, cols = (size_t)cols_raw;
    const size_t cells = rows * cols;
    if (length != 2 + 2 * cells) return -1;
    if (output == NULL || output_capacity < cells * BYTES_PER_VALUE) return -2;

    const size_t data_start = 2, mask_start = data_start + cells;
    size_t written = 0;
    for (size_t col = 0; col < cols; ++col) {
        for (size_t row = 0; row < rows; ++row) {
            const size_t index = row * cols + col;
            if (input[mask_start + index] > 0) {
                store_i64_le(output, written * BYTES_PER_VALUE, input[data_start + index]);
                ++written;
            }
        }
    }
    return (int64_t)written;
}
