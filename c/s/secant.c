#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double objective(double x) { return x * x - 3.0; }

double secant(const int64_t *values, size_t length)
{
    if (values == NULL || length != 5 || values[0] != 0 ||
        values[1] < 1000000 || values[1] > 1500000 ||
        values[2] < 1600000 || values[2] > 2000000 || values[1] >= values[2] ||
        values[3] < 1 || values[3] > 100000 || values[4] < 0 || values[4] > 32) {
        return INVALID_RESULT;
    }
    double x0 = (double)values[1] / 1000000.0;
    double x1 = (double)values[2] / 1000000.0;
    const double tolerance = (double)values[3] / 1000000000.0;
    const int64_t max_updates = values[4];
    for (int64_t update = 0; update <= max_updates; ++update) {
        const double f1 = objective(x1);
        if (fabs(f1) <= tolerance) return x1;
        if (update == max_updates) break;
        const double f0 = objective(x0);
        const double denominator = f1 - f0;
        if (denominator == 0.0) return INVALID_RESULT;
        const double x2 = x1 - f1 * (x1 - x0) / denominator;
        if (!isfinite(x2)) return INVALID_RESULT;
        x0 = x1;
        x1 = x2;
    }
    return INVALID_RESULT;
}
