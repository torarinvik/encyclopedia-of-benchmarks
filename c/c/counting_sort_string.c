/* Portable byte counting sort for printable non-space ASCII characters. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT_LENGTH 4095

int64_t counting_sort_string(const int64_t *values, size_t length,
                             uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 1 || length > MAX_TEXT_LENGTH + 1) return -1;
    const int64_t count = values[0];
    if (count < 0 || count > MAX_TEXT_LENGTH || length != (size_t)count + 1) return -1;

    size_t frequencies[256] = {0};
    for (size_t index = 0; index < (size_t)count; ++index) {
        const int64_t value = values[index + 1];
        if (value < 33 || value > 126) return -1;
        ++frequencies[(uint8_t)value];
    }
    if (output == NULL || output_capacity < (size_t)count) return -2;

    for (size_t value = 1; value < 256; ++value)
        frequencies[value] += frequencies[value - 1];
    for (size_t index = (size_t)count; index > 0; --index) {
        const uint8_t value = (uint8_t)values[index];
        output[--frequencies[value]] = value;
    }
    return count;
}
