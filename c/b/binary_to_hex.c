#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096
#define INVALID_RESULT INT64_C(-1)
#define CAPACITY_ERROR INT64_C(-2)

int64_t binary_to_hex(const int64_t *values, size_t length,
                      uint8_t *output, size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return INVALID_RESULT;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] != '0' && values[i] != '1') return INVALID_RESULT;
    }

    const size_t output_length = (length + 3) / 4;
    if (output_length == 0) return 0;
    if (output == NULL || output_capacity < output_length) return CAPACITY_ERROR;

    size_t first_width = length % 4;
    if (first_width == 0) first_width = 4;
    size_t start = 0;
    for (size_t group = 0; group < output_length; ++group) {
        const size_t width = group == 0 ? first_width : 4;
        int nibble = 0;
        for (size_t offset = 0; offset < width; ++offset) {
            nibble = nibble * 2 + (int)(values[start + offset] - '0');
        }
        output[group] = (uint8_t)(nibble < 10 ? '0' + nibble : 'A' + nibble - 10);
        start += width;
    }
    return (int64_t)output_length;
}
