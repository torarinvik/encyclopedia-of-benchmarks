/* Convert an ASCII binary string to equal-width ASCII Gray code. */
#include <stddef.h>
#include <stdint.h>

int64_t binary_to_gray(const int64_t *bits, size_t length,
                       uint8_t *output, size_t output_capacity)
{
    if (bits == NULL || length == 0 || length > 66) return -1;
    for (size_t index = 0; index < length; ++index)
        if (bits[index] != '0' && bits[index] != '1') return -1;
    if (output == NULL || output_capacity < length) return -2;
    for (size_t index = 0; index < length; ++index) {
        const int current = (int)(bits[index] - '0');
        const int previous = index == 0 ? 0 : (int)(bits[index - 1] - '0');
        output[index] = (uint8_t)('0' + (current ^ previous));
    }
    return (int64_t)length;
}
