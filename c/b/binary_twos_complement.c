/* Emit the pinned minimal-width two's-complement string for a signed integer. */
#include <stddef.h>
#include <stdint.h>

int64_t twos_complement(int64_t value, uint8_t *output, size_t output_capacity)
{
    if (value > 0) return -1;
    if (value == 0) {
        if (output == NULL || output_capacity < 3) return -2;
        output[0] = '0'; output[1] = 'b'; output[2] = '0';
        return 3;
    }
    const uint64_t magnitude = (uint64_t)(-(value + 1)) + UINT64_C(1);
    size_t bit_length = 0;
    for (uint64_t remaining = magnitude; remaining != 0; remaining >>= 1) ++bit_length;
    const uint64_t suffix = bit_length == 64 ? magnitude : (UINT64_C(1) << bit_length) - magnitude;
    uint8_t bits[64];
    size_t bit_count = 0;
    for (uint64_t remaining = suffix; remaining != 0; remaining >>= 1)
        bits[bit_count++] = (uint8_t)('0' + (remaining & 1U));
    const size_t required = bit_length + 3;
    if (output == NULL || output_capacity < required) return -2;
    size_t position = 0;
    output[position++] = '0'; output[position++] = 'b'; output[position++] = '1';
    for (size_t zero = bit_count; zero < bit_length; ++zero) output[position++] = '0';
    while (bit_count > 0) output[position++] = bits[--bit_count];
    return (int64_t)position;
}
