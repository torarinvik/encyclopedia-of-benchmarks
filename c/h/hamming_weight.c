#include <stdint.h>

int64_t hamming_weight(int64_t value) {
    if (value < 0 || (uint64_t)value > UINT32_MAX) return -1;
    const uint32_t number = (uint32_t)value;
    int64_t count = 0;
    for (unsigned bit = 0; bit < 32; ++bit)
        count += (number >> bit) & UINT32_C(1);
    return count;
}
