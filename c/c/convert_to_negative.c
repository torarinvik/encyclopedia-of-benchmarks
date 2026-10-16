/* Portable byte-channel negative transform. */
#include <stddef.h>
#include <stdint.h>

int64_t convert_to_negative(const int64_t *values, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > 4096) return -1;
    const int64_t count = values[0];
    if (count < 0 || count > 4095 || (size_t)count != length - 1) return -1;
    for (size_t index = 0; index < (size_t)count; ++index)
        if (values[index + 1] < 0 || values[index + 1] > 255) return -1;
    if ((size_t)count > output_capacity || (count != 0 && output == NULL)) return -2;
    for (size_t index = 0; index < (size_t)count; ++index)
        output[index] = (uint8_t)(255 - values[index + 1]);
    return count;
}
