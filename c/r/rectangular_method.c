#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double integrand(double x)
{
    return (exp(x) / 2.0) * (cos(x) - sin(x));
}

double rectangular_method(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t a_quarters = values[0], b_quarters = values[1];
    const int64_t intervals = values[2], rule = values[3];
    if (a_quarters < -64 || a_quarters >= b_quarters || b_quarters > 64 ||
        intervals < 1 || intervals > 64 ||
        (b_quarters - a_quarters) % intervals != 0 ||
        (rule != 0 && rule != 1)) return INVALID_RESULT;

    const double a = (double)a_quarters / 4.0;
    const double b = (double)b_quarters / 4.0;
    const double step = (b - a) / (double)intervals;
    double x = a, total = 0.0;
    for (int64_t i = 0; i < intervals; ++i) {
        if (rule == 0) {
            total += integrand(x) * step;
            x += step;
        } else {
            x += step;
            total += integrand(x) * step;
        }
    }
    return total;
}
