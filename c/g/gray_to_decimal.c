#include <stddef.h>
#include <stdint.h>

int64_t gray_to_decimal(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 64) return -1;
    const int64_t bit_length = values[0];
    if (bit_length < 1 || bit_length > 63 || length != (size_t)bit_length + 1) return -1;

    int64_t prefix = 0;
    int64_t binary = 0;
    for (size_t index = 1; index < length; ++index) {
        if (values[index] != 48 && values[index] != 49) return -1;
        prefix ^= values[index] - 48;
        binary = binary * 2 + prefix;
    }
    return binary;
}
