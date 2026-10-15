/* Stable nonzero compaction followed by a zero-fill pass. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static void write_i32_le(uint8_t *output, size_t index, int64_t value)
{
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[index * 4 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t move_zeroes(const int64_t *input, size_t length,
                    uint8_t *output, size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
    const size_t output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    size_t write_index = 0;
    for (size_t index = 0; index < length; ++index)
        if (input[index] != 0) write_i32_le(output, write_index++, input[index]);
    while (write_index < length) write_i32_le(output, write_index++, 0);
    return (int64_t)length;
}
