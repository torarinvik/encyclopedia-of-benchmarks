#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 32
#define MAX_INPUT_LENGTH (2 + MAX_DIMENSION * MAX_DIMENSION)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t matrix_copy(const int64_t *values, size_t length, uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t rows_value = values[0], columns_value = values[1];
    if (rows_value < 0 || rows_value > MAX_DIMENSION || columns_value < 0 || columns_value > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    const size_t element_count = rows * columns;
    if (length != 2 + element_count) return -1;
    for (size_t index = 0; index < element_count; ++index)
        if (values[2 + index] < INT32_MIN || values[2 + index] > INT32_MAX) return -1;
    const size_t result_rows = rows == 0 || columns == 0 ? 0 : rows;
    const size_t result_columns = rows == 0 || columns == 0 ? 0 : columns;
    const size_t result_count = result_rows * result_columns;
    const size_t output_bytes = (2 + result_count) * 8;
    if (output == NULL || output_capacity < output_bytes) return -2;
    store_i64_le(output, 0, (int64_t)result_rows);
    store_i64_le(output, 8, (int64_t)result_columns);
    for (size_t index = 0; index < result_count; ++index)
        store_i64_le(output, 16 + index * 8, values[2 + index]);
    return (int64_t)output_bytes;
}
