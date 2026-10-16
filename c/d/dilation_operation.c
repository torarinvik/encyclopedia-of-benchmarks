#include <stddef.h>
#include <stdint.h>

#define MAX_DIMENSION 16
#define MAX_INPUT_LENGTH (2 + MAX_DIMENSION * MAX_DIMENSION + 9)
#define INVALID_RESULT INT64_MIN

static void put_i32_le(uint8_t *output, size_t offset, int32_t value) {
    uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t dilation_operation(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 12 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t rows_value = input[0], columns_value = input[1];
    if (rows_value < 1 || rows_value > MAX_DIMENSION || columns_value < 1 || columns_value > MAX_DIMENSION) return -1;
    const size_t rows = (size_t)rows_value, columns = (size_t)columns_value;
    const size_t cells = rows * columns;
    if (length != 2 + cells + 9) return -1;
    for (size_t i = 0; i < cells + 9; ++i) if (input[2 + i] < 0 || input[2 + i] > 1) return -1;
    const size_t output_bytes = cells * 4;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t y = 0; y < rows; ++y) {
        for (size_t x = 0; x < columns; ++x) {
            int sum = 0;
            for (size_t ky = 0; ky < 3; ++ky) {
                for (size_t kx = 0; kx < 3; ++kx) {
                    const int64_t image_y = (int64_t)y + (int64_t)ky - 1;
                    const int64_t image_x = (int64_t)x + (int64_t)kx - 1;
                    if (image_y >= 0 && image_y < (int64_t)rows && image_x >= 0 && image_x < (int64_t)columns)
                        sum += (int)(input[2 + (size_t)image_y * columns + (size_t)image_x] * input[2 + cells + ky * 3 + kx]);
                }
            }
            put_i32_le(output, (y * columns + x) * 4, sum > 0 ? 1 : 0);
        }
    }
    return (int64_t)cells;
}
