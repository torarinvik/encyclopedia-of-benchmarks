/* Decode one-based alphabet positions as lowercase ASCII letters. */
#include <stddef.h>
#include <stdint.h>

int64_t a1z26_decipher(const int64_t *input, size_t length, uint8_t *output,
                       size_t output_capacity)
{
    if (length > 66) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 26) return -1;
    if (output_capacity < length) return -2;
    for (size_t index = 0; index < length; ++index)
        output[index] = (uint8_t)(96 + input[index]);
    return (int64_t)length;
}
