/* Pinned Python GELU approximation: x * (1 / (1 + exp(-1.702*x))). */
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double gaussian_error_linear_unit(double x)
{
    if (!isfinite(x) || x < -100.0 || x > 100.0) return INVALID_RESULT;
    return x * (1.0 / (1.0 + exp(-1.702 * x)));
}
