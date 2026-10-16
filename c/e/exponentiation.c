#include <stdint.h>
int64_t exponentiation(int64_t base, int64_t exponent) {
    if (base < 0 || base > 255 || exponent < 0 || exponent > 7) return -1;
    int64_t result = 1;
    for (int64_t i = 0; i < exponent; ++i) result *= base;
    return result;
}
