#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(16)
#define MIN_BOUND (-INT64_C(10000000))
#define MAX_BOUND INT64_C(10000000)
#define MIN_UNIFORM INT64_C(0)
#define MAX_UNIFORM INT64_C(999999)
#define INVALID_RESULT (-1.0e300)

double monte_carlo_integration(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 3 || length > 12) return INVALID_RESULT;
    const int64_t n = packed[2];
    if (n < 1 || n > MAX_N || length != (size_t)(3 + (n + 1) / 2)) return INVALID_RESULT;
    const int64_t a_raw = packed[0];
    const int64_t b_raw = packed[1];
    if (a_raw < MIN_BOUND || a_raw > MAX_BOUND || b_raw < MIN_BOUND || b_raw > MAX_BOUND || a_raw >= b_raw) return INVALID_RESULT;

    for (size_t i = 3; i < length; ++i) {
        if (packed[i] < MIN_UNIFORM || packed[i] > MAX_UNIFORM) return INVALID_RESULT;
    }

    const double a = (double)a_raw / 1000000.0;
    const double b = (double)b_raw / 1000000.0;
    const double interval = b - a;
    double total = 0.0;
    for (int64_t i = 0; i < n / 2; ++i) {
        const double u = (double)packed[3 + (size_t)i] / 1000000.0;
        const double x1 = a + u * interval;
        const double x2 = a + (1.0 - u) * interval;
        total += x1 * x1;
        total += x2 * x2;
    }
    if ((n & 1) == 1) {
        const double u = (double)packed[3 + (size_t)(n / 2)] / 1000000.0;
        const double x = a + u * interval;
        total += x * x;
    }
    return interval * total / (double)n;
}
