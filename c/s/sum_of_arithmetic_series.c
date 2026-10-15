#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double sum_of_arithmetic_series(const int64_t *packed, size_t length)
{
    if (packed == NULL || length != 3) return INVALID_RESULT;
    const int64_t a = packed[0];
    const int64_t d = packed[1];
    const int64_t n = packed[2];
    if (a < -1000 || a > 1000 || d < -1000 || d > 1000 || n < 1 || n > 1000) return INVALID_RESULT;
    const int64_t result = n * (2 * a + (n - 1) * d) / 2;
    return (double)result;
}
