/* Convert a packed most-significant-first binary digit array to signed i64. */
#include <stddef.h>
#include <stdint.h>

int64_t binary_to_decimal(const int64_t *bits, size_t length)
{
    if (length == 0 || length > 63 || bits == NULL) return -1;
    uint64_t value = 0;
    for (size_t index = 0; index < length; ++index) {
        if (bits[index] != 0 && bits[index] != 1) return -1;
        value = value * 2 + (uint64_t)bits[index];
    }
    return (int64_t)value;
}
