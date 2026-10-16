#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 16
#define LIMIT INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double neville(const int64_t *values, size_t length) {
    if (values == NULL || length < 4 || length > 34) return INVALID_RESULT;
    const int64_t count = values[0], target_i = values[1];
    if (count < 1 || count > MAX_POINTS || length != (size_t)(2 * count + 2) || target_i < -LIMIT || target_i > LIMIT) return INVALID_RESULT;
    double x[MAX_POINTS], p[MAX_POINTS];
    for (size_t i = 0; i < (size_t)count; ++i) {
        const int64_t xi = values[2 + 2 * i], yi = values[3 + 2 * i];
        if (xi < -LIMIT || xi > LIMIT || yi < -LIMIT || yi > LIMIT) return INVALID_RESULT;
        for (size_t j = 0; j < i; ++j) if (values[2 + 2 * j] == xi) return INVALID_RESULT;
        x[i] = (double)xi; p[i] = (double)yi;
    }
    const double target = (double)target_i;
    for (size_t k = 1; k < (size_t)count; ++k)
        for (size_t i = 0; i < (size_t)count - k; ++i)
            p[i] = ((target - x[i + k]) * p[i] + (x[i] - target) * p[i + 1]) / (x[i] - x[i + k]);
    return p[0];
}
