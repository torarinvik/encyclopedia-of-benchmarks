#include <stdint.h>

int64_t parity_check(int64_t value)
{
    if (value < INT32_MIN || value > INT32_MAX) return -1;
    int32_t number = (int32_t)value;
    int parity = 0;
    while (number > 0) {
        parity ^= number & 1;
        number >>= 1;
    }
    return parity == 0 ? 1 : 0;
}
