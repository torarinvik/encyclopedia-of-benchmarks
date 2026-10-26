#include <stddef.h>
#include <stdint.h>

int64_t beebs_bit_compress(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2 ||
        values[0] < 0 || values[0] > INT64_C(4294967295) ||
        values[1] < 0 || values[1] > INT64_C(4294967295)) {
        return -1;
    }

    uint32_t data = (uint32_t)values[0];
    uint32_t mask = (uint32_t)values[1];
    uint32_t packed = 0;
    uint32_t output_bit = 1;
    while (mask != 0) {
        if (mask & 1u) {
            if (data & 1u) packed |= output_bit;
            output_bit <<= 1;
        }
        data >>= 1;
        mask >>= 1;
    }
    return (int64_t)packed;
}
