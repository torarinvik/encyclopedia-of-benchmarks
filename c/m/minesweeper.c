#include <stddef.h>
#include <stdint.h>

#define MS_MAX_DIM 32
#define MS_MAX_INPUT (2 + MS_MAX_DIM * MS_MAX_DIM)
#define MS_MAX_OUTPUT (8 + 8 * MS_MAX_DIM * MS_MAX_DIM)

static size_t ms_write_i64(uint8_t *output, size_t position, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[position++] = (uint8_t)(bits >> (8 * i));
    return position;
}

int64_t minesweeper(const int64_t *input, size_t length,
                    uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MS_MAX_INPUT) return -1;
    const int64_t rows_value = input[0], cols_value = input[1];
    if (rows_value < 1 || rows_value > MS_MAX_DIM || cols_value < 1 || cols_value > MS_MAX_DIM) return -1;
    const size_t rows = (size_t)rows_value, cols = (size_t)cols_value;
    const size_t cells_count = rows * cols;
    if (length != 2 + cells_count) return -1;
    uint8_t cells[MS_MAX_DIM * MS_MAX_DIM];
    for (size_t i = 0; i < cells_count; ++i) {
        if (input[2 + i] != 0 && input[2 + i] != 1) return -1;
        cells[i] = (uint8_t)input[2 + i];
    }
    uint8_t counts[MS_MAX_DIM * MS_MAX_DIM];
    for (size_t row = 0; row < rows; ++row) {
        for (size_t col = 0; col < cols; ++col) {
            unsigned count = 0;
            for (int dr = -1; dr <= 1; ++dr) {
                for (int dc = -1; dc <= 1; ++dc) {
                    if (dr == 0 && dc == 0) continue;
                    const int nr = (int)row + dr, nc = (int)col + dc;
                    if (nr >= 0 && nr < (int)rows && nc >= 0 && nc < (int)cols &&
                        cells[(size_t)nr * cols + (size_t)nc] == 1) ++count;
                }
            }
            counts[row * cols + col] = (uint8_t)count;
        }
    }
    const size_t needed = 8 + 8 * cells_count;
    if (output == NULL || output_capacity < needed) return -2;
    size_t written = ms_write_i64(output, 0, (int64_t)cells_count);
    for (size_t i = 0; i < cells_count; ++i) written = ms_write_i64(output, written, counts[i]);
    return (int64_t)written;
}
