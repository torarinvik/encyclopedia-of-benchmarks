#include <math.h>
#include <stdint.h>

int64_t binary_length(int64_t value)
{
    if (value <= 0 || value > INT32_MAX) return -1;
    return (int64_t)(floor(log2((double)value)) + 1.0);
}
