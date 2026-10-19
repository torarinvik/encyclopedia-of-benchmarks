#include <stddef.h>
#include <stdint.h>

static int64_t power_using_recursion_value(int64_t base, int64_t exponent)
{
    if (exponent == 0) return 1;
    return base * power_using_recursion_value(base, exponent - 1);
}

int64_t power_using_recursion(const int64_t *input, size_t length)
{
    if (input == NULL || length != 2) return -1;
    const int64_t base = input[0];
    const int64_t exponent = input[1];
    if (base < -10 || base > 10 || exponent < 0 || exponent > 15) return -1;
    return power_using_recursion_value(base, exponent);
}
