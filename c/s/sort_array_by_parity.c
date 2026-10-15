/* Place even values first and write odd values from the output end inward. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 5000

int64_t sort_array_by_parity(const int64_t *input, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 5000) return -1;
    const size_t output_bytes = length * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;

    size_t even_index = 0, odd_index = length;
    for (size_t index = 0; index < length; ++index) {
        const uint32_t value = (uint32_t)input[index];
        size_t destination;
        if ((value & 1U) == 0) {
            destination = even_index++;
        } else {
            destination = --odd_index;
        }
        for (size_t byte = 0; byte < 4; ++byte)
            output[destination * 4 + byte] = (uint8_t)(value >> (byte * 8));
    }
    return (int64_t)length;
}
