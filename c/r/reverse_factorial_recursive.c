#include <stdint.h>

static int64_t reverse_factorial_recursive_impl(int64_t value, int64_t divisor)
{
    if (value == 1) return divisor == 1 ? 1 : divisor - 1;
    if (value % divisor != 0) return -1;
    return reverse_factorial_recursive_impl(value / divisor, divisor + 1);
}

int64_t reverse_factorial_recursive(int64_t value)
{
    if (value < 1) return -1;
    return reverse_factorial_recursive_impl(value, 1);
}
