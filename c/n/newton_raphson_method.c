#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
static double equation(double x) { return pow(x, 3.0) - (4.0 * x) - 9.0; }
static double derivative(double x) { return 3.0 * pow(x, 2.0) - 4.0; }

double newton_raphson_method(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    const int64_t initial_milli = values[0], iteration_limit = values[1];
    if (initial_milli < 2000 || initial_milli > 4000 || iteration_limit < 1 || iteration_limit > 32)
        return INVALID_RESULT;
    double c = (double)initial_milli / 1000.0;
    double z = c;
    for (int64_t iteration = 0; iteration < iteration_limit; ++iteration) {
        const double m = equation(c);
        const double n = derivative(c);
        z = c - (m / n);
        c = z;
        if (fabs(m) < 1e-10) break;
    }
    return z;
}
