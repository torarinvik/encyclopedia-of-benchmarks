#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 258u
#define MAX_LIST_LENGTH 256u

static void write_i32_le(uint8_t *output, size_t index, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    const size_t offset = index * 4u;
    output[offset] = (uint8_t)bits;
    output[offset + 1u] = (uint8_t)(bits >> 8u);
    output[offset + 2u] = (uint8_t)(bits >> 16u);
    output[offset + 3u] = (uint8_t)(bits >> 24u);
}

int64_t reverse_kgroup(const int32_t *input, size_t length,
                       uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1u || length > MAX_INPUT_LENGTH) return -1;
    const int32_t group_size_value = input[0];
    const size_t list_length = length - 1u;
    if (group_size_value < 1 || group_size_value > (int32_t)MAX_LIST_LENGTH
        || list_length > MAX_LIST_LENGTH) return -1;
    const size_t group_size = (size_t)group_size_value;
    const size_t output_bytes = list_length * 4u;
    if (output == NULL || output_capacity < output_bytes) return -2;

    size_t start = 0u;
    while (start + group_size <= list_length) {
        for (size_t offset = 0; offset < group_size; ++offset)
            write_i32_le(output, start + offset, input[1u + start + group_size - 1u - offset]);
        start += group_size;
    }
    while (start < list_length) {
        write_i32_le(output, start, input[1u + start]);
        ++start;
    }
    return (int64_t)output_bytes;
}
