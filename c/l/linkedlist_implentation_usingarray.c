#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 202u
#define MAX_OPERATIONS 100
#define MAX_LIST_LENGTH 100u

static void write_i32_le(uint8_t *output, size_t index, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    const size_t offset = index * 4u;
    output[offset] = (uint8_t)bits;
    output[offset + 1u] = (uint8_t)(bits >> 8u);
    output[offset + 2u] = (uint8_t)(bits >> 16u);
    output[offset + 3u] = (uint8_t)(bits >> 24u);
}

int64_t linkedlist_implentation_usingarray(const int64_t *input, size_t length,
                                           uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation_count = input[0];
    if (operation_count < 0 || operation_count > MAX_OPERATIONS
        || length != 1u + 2u * (size_t)operation_count) return -1;

    int32_t items[MAX_LIST_LENGTH];
    size_t item_count = 0u, cursor = 1u;
    for (int64_t step = 0; step < operation_count; ++step) {
        const int64_t opcode = input[cursor++];
        const int64_t raw_value = input[cursor++];
        if (raw_value < INT32_MIN || raw_value > INT32_MAX || item_count >= MAX_LIST_LENGTH) return -1;
        const int32_t value = (int32_t)raw_value;
        if (opcode == 0) {
            for (size_t index = item_count; index > 0u; --index)
                items[index] = items[index - 1u];
            items[0] = value;
            ++item_count;
        } else if (opcode == 1) {
            if (item_count == 0u) return -1;
            items[item_count++] = value;
        } else {
            return -1;
        }
    }

    const size_t output_bytes = (item_count + 1u) * 4u;
    if (output == NULL || output_capacity < output_bytes) return -2;
    write_i32_le(output, 0u, (int32_t)item_count);
    for (size_t index = 0; index < item_count; ++index)
        write_i32_le(output, index + 1u, items[index]);
    return (int64_t)output_bytes;
}
