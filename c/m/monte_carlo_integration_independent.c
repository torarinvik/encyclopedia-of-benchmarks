#include <stddef.h>
#include <stdint.h>

#define MAX_N INT64_C(16)
#define MIN_BOUND (-INT64_C(10000000))
#define MAX_BOUND INT64_C(10000000)
#define MAX_UNIFORM INT64_C(999999)
#define INVALID_RESULT (-1.0e300)

double monte_carlo_integration_independent(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 3 || length > 20) return INVALID_RESULT;
    const int64_t n = packed[2];
    if (n < 1 || n > MAX_N || length != (size_t)(3 + n)) return INVALID_RESULT;
    const int64_t a_raw = packed[0];
    const int64_t b_raw = packed[1];
    if (a_raw < MIN_BOUND || a_raw > MAX_BOUND || b_raw < MIN_BOUND || b_raw > MAX_BOUND || a_raw >= b_raw) return INVALID_RESULT;
    for (size_t i = 3; i < length; ++i) {
        if (packed[i] < 0 || packed[i] > MAX_UNIFORM) return INVALID_RESULT;
    }

    const double a = (double)a_raw / 1000000.0;
    const double b = (double)b_raw / 1000000.0;
    const double interval = b - a;
    const double delta = interval / (double)n;
    double total = 0.0;
    for (int64_t i = 0; i < n; ++i) {
        const double u = (double)packed[3 + (size_t)i] / 1000000.0;
        const double x = a + interval * u;
        total += x * x;
    }
    return delta * total;
}
