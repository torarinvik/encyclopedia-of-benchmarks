#include <stdint.h>

int64_t max_value(int64_t a, int64_t b)
{
    if (a < INT32_MIN || a > INT32_MAX || b < INT32_MIN || b > INT32_MAX) return -1;
    return a >= b ? a : b;
}
