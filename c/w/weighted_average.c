#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(64)
#define MAX_ABS_VALUE INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double weighted_average(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 1 || length > 129) return INVALID_RESULT;
    const int64_t n = packed[0];
    if (n < 1 || n > MAX_N || length != (size_t)(1 + 2 * n)) return INVALID_RESULT;
    int64_t weighted_sum = 0;
    int64_t total_weight = 0;
    for (int64_t i = 0; i < n; ++i) {
        const int64_t value = packed[1 + (size_t)i];
        const int64_t weight = packed[1 + (size_t)n + (size_t)i];
        if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE ||
            weight < -MAX_ABS_VALUE || weight > MAX_ABS_VALUE) return INVALID_RESULT;
        weighted_sum += value * weight;
        total_weight += weight;
    }
    if (total_weight == 0) return INVALID_RESULT;
    return (double)weighted_sum / (double)total_weight;
}
