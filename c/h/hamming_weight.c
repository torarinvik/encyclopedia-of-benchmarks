#include <stdint.h>

int64_t hamming_weight(int64_t value) {
    if (value < 0 || (uint64_t)value > UINT32_MAX) return -1;
    return __builtin_popcount((uint32_t)value);
}
