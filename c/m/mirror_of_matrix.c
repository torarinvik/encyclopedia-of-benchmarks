#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_INPUT_LENGTH 259
#define MAX_DIMENSION 16
#define I32_MIN_VALUE (-2147483647LL - 1)
#define I32_MAX_VALUE 2147483647LL

static void store_i32_le(uint8_t *output, size_t offset, int32_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t mirror_of_matrix(const int64_t *values, size_t length,
                         uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_rows = values[0], raw_columns = values[1];
    if (raw_rows < 1 || raw_rows > MAX_DIMENSION ||
        raw_columns < 1 || raw_columns > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)raw_rows, columns = (size_t)raw_columns;
    const size_t cell_count = rows * columns;
    if (length != 2 + cell_count) return -1;
    for (size_t index = 0; index < cell_count; ++index)
        if (values[2 + index] < I32_MIN_VALUE || values[2 + index] > I32_MAX_VALUE) return -1;

    const size_t byte_count = 4 * cell_count;
    if (output == NULL || capacity < byte_count) return -2;
    for (size_t row = 0; row < rows; ++row)
        for (size_t column = 0; column < columns; ++column)
            store_i32_le(output, 4 * (row * columns + column),
                         (int32_t)values[2 + row * columns + (columns - 1 - column)]);
    return (int64_t)byte_count;
}
