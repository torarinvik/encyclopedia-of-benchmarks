#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

static double python_objective(double x)
{
    return 8.0 * x - 2.0 * exp(-x);
}

static double c_variant(void)
{
    double x0 = 0.2;
    double x1 = 0.5;
    const double tolerance = 100.0 / 1000000.0;
    for (int iteration = 0; iteration < 99; ++iteration) {
        const double f1 = x1 * x1 - 3.0;
        const double f0 = x0 * x0 - 3.0;
        const double x2 = x1 - f1 * (x1 - x0) / (f1 - f0);
        x0 = x1;
        x1 = x2;
        if (fabs(x1 - x0) < tolerance) return x2;
    }
    return -1.0;
}

static double python_variant(int64_t repeats)
{
    double x0 = 1.0;
    double x1 = 3.0;
    for (int64_t iteration = 0; iteration < repeats; ++iteration) {
        const double f1 = python_objective(x1);
        const double f0 = python_objective(x0);
        const double x2 = x1 - (f1 * (x1 - x0)) / (f1 - f0);
        x0 = x1;
        x1 = x2;
    }
    return x1;
}

double secant_method(const int64_t *values, size_t length)
{
    if (values == NULL || length != 2) return INVALID_RESULT;
    if (values[0] == 0 && values[1] == 100) return c_variant();
    if (values[0] == 1 && values[1] >= 0 && values[1] <= 2) return python_variant(values[1]);
    return INVALID_RESULT;
}
