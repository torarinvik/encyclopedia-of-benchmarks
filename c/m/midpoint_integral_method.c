#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double integrand(int64_t function_id, double x)
{
    switch (function_id) {
    case 0: return sqrt(x) + log(x);
    case 1: return exp(-x) * (4.0 - pow(x, 2.0));
    case 2: return sqrt(2.0 * pow(x, 3.0) + 3.0);
    case 3: return x + log(2.0 * x + 1.0);
    default: return INVALID_RESULT;
    }
}

double midpoint_integral_method(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t function_id = values[0], intervals = values[1];
    const int64_t a_milli = values[2], b_milli = values[3];
    if (function_id < 0 || function_id > 3 || intervals < 2 || intervals > 64 || intervals % 2 != 0 ||
        a_milli < 0 || a_milli >= b_milli || b_milli > 10000) return INVALID_RESULT;
    const double a = (double)a_milli / 1000.0;
    const double b = (double)b_milli / 1000.0;
    const double h = (b - a) / (double)intervals;
    double xi = a, sum = 0.0;
    for (int64_t i = 0; i < intervals; ++i) {
        sum += integrand(function_id, xi + h / 2.0);
        xi += h;
    }
    return sum * h;
}
