#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_N 128
#define DELTA 1.0e-9

double correlation(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3) return INVALID_RESULT;
    const int64_t n_value = values[0];
    if (n_value < 1 || n_value > MAX_N || length != 1 + 2 * (size_t)n_value) return INVALID_RESULT;
    const size_t n = (size_t)n_value;
    double exy = 0.0, ex = 0.0, exx = 0.0, ey = 0.0, eyy = 0.0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t xi = values[1 + i];
        const int64_t yi = values[1 + n + i];
        if (xi < -1000 || xi > 1000 || yi < -1000 || yi > 1000) return INVALID_RESULT;
        const double x = (double)xi, y = (double)yi;
        exy += x * y;
        ex += x;
        exx += x * x;
        ey += y;
        eyy += y * y;
    }
    exy /= (double)n;
    ex /= (double)n;
    exx /= (double)n;
    ey /= (double)n;
    eyy /= (double)n;
    const double cov = exy - ex * ey;
    const double varx = sqrt(exx - ex * ex);
    const double vary = sqrt(eyy - ey * ey);
    if (varx * vary < DELTA) return 0.0;
    return cov / sqrt(varx * vary);
}
