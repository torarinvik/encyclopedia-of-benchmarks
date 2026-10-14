#include <stddef.h>
#include <stdint.h>

#define MAX_I32 INT64_C(2147483647)
#define MAX_RESULT UINT64_C(9223372036854775807)

int64_t binary_exponentiation(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return -1;
    const int64_t base_input = values[0], exponent_input = values[1];
    if (base_input < 0 || base_input > MAX_I32 || exponent_input < 0 || exponent_input > MAX_I32) return -1;
    uint64_t base = (uint64_t)base_input, exponent = (uint64_t)exponent_input, result = 1;
    while (exponent != 0) {
        if ((exponent & 1U) != 0) {
            if (base != 0 && result > MAX_RESULT / base) return -1;
            result *= base;
        }
        exponent >>= 1;
        if (exponent != 0) {
            if (base != 0 && base > MAX_RESULT / base) return -1;
            base *= base;
        }
    }
    return (int64_t)result;
}
