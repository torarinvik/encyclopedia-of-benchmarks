/* Swap adjacent node values in a bounded array representation of a list. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024

int64_t swap_pairs(const int64_t *input, size_t length, uint8_t *output,
                   size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < INT32_MIN || input[index] > INT32_MAX) return -1;
    const size_t output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;

    for (size_t index = 0; index < length; ++index) {
        const size_t pair_start = (index / 2) * 2;
        const size_t source_index = (index % 2 == 0 && pair_start + 1 < length)
            ? pair_start + 1 : (index % 2 == 0 ? pair_start : pair_start);
        const uint32_t bits = (uint32_t)(int32_t)input[source_index];
        for (size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return (int64_t)length;
}
