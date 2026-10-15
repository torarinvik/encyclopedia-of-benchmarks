#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(8)
#define MAX_P INT64_C(6)
#define INVALID_RESULT (-1.0e300)

double minkowski_distance(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 18) return INVALID_RESULT;
    const int64_t n = packed[0];
    const int64_t p = packed[1];
    if (n < 0 || n > MAX_N || p < 3 || p > MAX_P || length != (size_t)(2 + 2 * n)) return INVALID_RESULT;
    for (int64_t i = 0; i < n; ++i) {
        if (packed[2 + (size_t)i] < -100 || packed[2 + (size_t)i] > 100 ||
            packed[2 + (size_t)n + (size_t)i] < -100 || packed[2 + (size_t)n + (size_t)i] > 100) return INVALID_RESULT;
    }
    int64_t sum = 0;
    for (int64_t i = 0; i < n; ++i) {
        int64_t difference = packed[2 + (size_t)i] - packed[2 + (size_t)n + (size_t)i];
        if (difference < 0) difference = -difference;
        int64_t term = 1;
        for (int64_t exponent = 0; exponent < p; ++exponent) term *= difference;
        sum += term;
    }
    return pow((double)sum, 1.0 / (double)p);
}
