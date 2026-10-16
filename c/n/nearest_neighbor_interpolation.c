#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 16
#define MAX_INPUT_LENGTH (2 + MAX_DIMENSION * MAX_DIMENSION)

int64_t nearest_neighbor_interpolation(const int64_t *input, size_t length,
                                       uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t rows_value = input[0];
    const int64_t columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION ||
        columns_value < 1 || columns_value > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)rows_value;
    const size_t columns = (size_t)columns_value;
    const size_t input_cells = rows * columns;
    if (length != 2 + input_cells) return -1;
    for (size_t index = 0; index < input_cells; ++index)
        if (input[index + 2] < 0 || input[index + 2] > 255) return -1;

    const size_t output_rows = (3 * rows) / 2;
    const size_t output_columns = (3 * columns) / 2;
    const size_t output_bytes = output_rows * output_columns;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t y = 0; y < output_rows; ++y) {
        const size_t source_y = (4 * (y + 1) + 3) / 6 - 1;
        for (size_t x = 0; x < output_columns; ++x) {
            const size_t source_x = (4 * (x + 1) + 3) / 6 - 1;
            output[y * output_columns + x] = (uint8_t)input[2 + source_y * columns + source_x];
        }
    }
    return (int64_t)output_bytes;
}
