#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256u

static void write_i32_le(uint8_t *output, size_t index, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    const size_t offset = index * 4u;
    output[offset] = (uint8_t)bits;
    output[offset + 1u] = (uint8_t)(bits >> 8u);
    output[offset + 2u] = (uint8_t)(bits >> 16u);
    output[offset + 3u] = (uint8_t)(bits >> 24u);
}

int64_t reverse_singly_linked_list(const int32_t *values, size_t length,
                                   uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length > MAX_LENGTH) return -1;
    const size_t output_bytes = length * 4u;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < length; ++index)
        write_i32_le(output, index, values[length - 1u - index]);
    return (int64_t)output_bytes;
}
