/* Duplicate each zero while retaining the fixed output length. */
#include <stddef.h>
#include <stdint.h>

static void write_i32(uint8_t *output, size_t position, int32_t value)
{
    const uint32_t encoded = (uint32_t)value;
    output[position] = (uint8_t)encoded;
    output[position + 1] = (uint8_t)(encoded >> 8);
    output[position + 2] = (uint8_t)(encoded >> 16);
    output[position + 3] = (uint8_t)(encoded >> 24);
}

int64_t duplicate_zeros(const int64_t *values, size_t length,
                        uint8_t *output, size_t output_capacity)
{
    if (length > 64) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 1000) return -1;
    const size_t required = 4 * length;
    if (output_capacity < required || (required > 0 && output == NULL)) return -2;
    size_t source = 0, destination = 0;
    while (destination < length) {
        const int64_t value = values[source++];
        write_i32(output, 4 * destination++, (int32_t)value);
        if (value == 0 && destination < length)
            write_i32(output, 4 * destination++, 0);
    }
    return (int64_t)length;
}
