#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
double mean_squared_logarithmic_error(const int64_t *values, size_t length) {
    if (values == NULL || length < 1) return INVALID_RESULT;
    const int64_t n = values[0];
    if (n < 1 || n > 64 || length != 1 + 2 * (size_t)n) return INVALID_RESULT;
    for (size_t i = 0; i < 2 * (size_t)n; i++) if (values[1 + i] < -999999 || values[1 + i] > 1000000) return INVALID_RESULT;
    double total = 0.0;
    for (size_t i = 0; i < (size_t)n; i++) { double t = (double)values[1+i] / SCALE, p = (double)values[1+(size_t)n+i] / SCALE;
        double d = log1p(t) - log1p(p); total += d * d;
    }
    return total / (double)n;
}
