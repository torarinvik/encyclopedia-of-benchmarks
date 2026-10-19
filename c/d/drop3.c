/* Bounded port of BitBench drop3: discard 3-bit codes below 4. */
#include <stddef.h>
#include <stdint.h>

#define DROP3_MAX_INPUT 4096

int64_t drop3(const int64_t *values, size_t length)
{
    static const unsigned offsets[8] = {0, 5, 2, 7, 4, 1, 6, 3};
    if (length > DROP3_MAX_INPUT + 1 || (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < 0 || values[i] > 255) return -1;
    if (length > DROP3_MAX_INPUT) return -1;

    int64_t output_size = 0;
    for (int iteration = 0; iteration < 20; ++iteration) {
        size_t input_index = 0;
        size_t remaining_bits = length * 8;
        unsigned phase = 0;
        uint16_t bit_buffer = 0;
        int output_bits = 0;
        while (remaining_bits >= 3) {
            remaining_bits -= 3;
            unsigned offset = offsets[phase];
            if (offset < 3)
                bit_buffer |= (uint16_t)((uint16_t)values[input_index++] << (8 - offset));
            unsigned code = (bit_buffer >> 13) & 7u;
            if (code >= 4) output_bits += 3;
            bit_buffer = (uint16_t)(bit_buffer << 3);
            phase = (phase + 1) & 7u;
        }
        output_size = output_bits >> 3;
    }
    return output_size;
}
