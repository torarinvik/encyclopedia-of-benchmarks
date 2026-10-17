#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0
#define MAX_ENDPOINT_MICRO INT64_C(10000000)

static double integrand(double x)
{
    return exp(-x) * (4.0 - pow(x, 2.0));
}

double simpson_integration(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t intervals = values[0];
    const int64_t a_micro = values[1];
    const int64_t b_micro = values[2];
    if (intervals < 2 || intervals > 128 || intervals % 2 != 0 ||
        a_micro < -MAX_ENDPOINT_MICRO || a_micro > MAX_ENDPOINT_MICRO ||
        b_micro < -MAX_ENDPOINT_MICRO || b_micro > MAX_ENDPOINT_MICRO || a_micro > b_micro) {
        return INVALID_RESULT;
    }

    const double a = (double)a_micro / SCALE;
    const double b = (double)b_micro / SCALE;
    if (a == b) return 0.0;
    const double h = (b - a) / (double)intervals;
    double xi = a;
    double total = 0.0;
    for (int64_t i = 0; i <= intervals; ++i) {
        const double sample = integrand(xi);
        if (i == 0 || i == intervals) total += sample;
        else if (i % 2 != 0) total += 4.0 * sample;
        else total += 2.0 * sample;
        xi += h;
    }
    return (h / 3.0) * total;
}
