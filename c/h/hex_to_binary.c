#include <stddef.h>
#include <stdint.h>

static int hex_value(int64_t value)
{
    if (value >= '0' && value <= '9') return (int)(value - '0');
    if (value >= 'A' && value <= 'F') return (int)(value - 'A' + 10);
    if (value >= 'a' && value <= 'f') return (int)(value - 'a' + 10);
    return -1;
}

int64_t hex_to_binary(const int64_t *values, size_t length,
                      uint8_t *output, size_t capacity)
{
    if (length > 256 || (length != 0 && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (hex_value(values[index]) < 0) return -1;
    }

    const size_t required = length * 4;
    if (output == NULL || capacity < required) return -2;
    for (size_t index = 0; index < length; ++index) {
        const int digit = hex_value(values[index]);
        for (size_t bit = 0; bit < 4; ++bit) {
            output[index * 4 + bit] = (uint8_t)(((digit >> (3 - bit)) & 1) ? '1' : '0');
        }
    }
    return (int64_t)required;
}
