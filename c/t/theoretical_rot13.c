/* Apply ROT13 only to lowercase non-NUL ASCII bytes. */
#include <stddef.h>
#include <stdint.h>

int64_t theoretical_rot13(const int64_t *input, size_t length, uint8_t *output,
                          size_t output_capacity)
{
    if (length > 66) return -1;
    for (size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    if (output_capacity < length) return -2;
    for (size_t index = 0; index < length; ++index) {
        const int64_t value = input[index];
        const int64_t mapped = value >= 'a' && value <= 'z'
            ? 'a' + (value - 'a' + 13) % 26 : value;
        output[index] = (uint8_t)mapped;
    }
    return (int64_t)length;
}
