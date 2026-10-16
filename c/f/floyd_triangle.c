/* Generate Floyd's triangle as flattened little-endian 16-bit values. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ROWS 90

int64_t floyd_triangle(int64_t rows, uint8_t *output, size_t output_capacity)
{
    if (rows < 0 || rows > MAX_ROWS) return -1;
    const size_t count = (size_t)rows * ((size_t)rows + 1) / 2;
    const size_t output_length = count * 2;
    if (output_capacity < output_length || (output_length != 0 && output == NULL)) return -2;

    size_t index = 0;
    uint32_t number = 1;
    for (size_t row = 1; row <= (size_t)rows; ++row) {
        for (size_t column = 0; column < row; ++column) {
            output[index * 2] = (uint8_t)(number & UINT32_C(0xff));
            output[index * 2 + 1] = (uint8_t)((number >> 8) & UINT32_C(0xff));
            ++number;
            ++index;
        }
    }
    return (int64_t)output_length;
}
