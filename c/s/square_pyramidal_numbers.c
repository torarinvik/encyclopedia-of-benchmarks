/* Exact square-pyramidal sum within the pinned u64 intermediate range. */
#include <stdint.h>

int64_t square_pyramidal_numbers(int64_t n)
{
    if (n < 0 || n > INT64_C(2097151)) return -1;
    const uint64_t value = (uint64_t)n;
    const uint64_t numerator = value * (value + 1) * (2 * value + 1);
    return (int64_t)(numerator / 6);
}
