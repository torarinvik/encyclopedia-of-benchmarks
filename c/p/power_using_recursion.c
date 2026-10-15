/* Linear recursive integer power, with a bounded exact contract. */
#include <stdint.h>

static int64_t decode_signed(uint64_t value)
{
    if (value <= INT64_MAX) return (int64_t)value;
    return -1 - (int64_t)(~value);
}

static int64_t power_recursive(int64_t base, uint64_t exponent)
{
    if (exponent == 0) return 1;
    return base * power_recursive(base, exponent - 1);
}

int64_t power_using_recursion(uint64_t base_encoded, uint64_t exponent)
{
    const int64_t base = decode_signed(base_encoded);
    if (base < -10 || base > 10 || exponent > 15) return INT64_MIN;
    return power_recursive(base, exponent);
}
