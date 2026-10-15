/* Pinned Python Swish expression with trainable_parameter fixed to 1. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double swish(double x)
{
    if (!isfinite(x) || x < -100.0 || x > 100.0) return INVALID_RESULT;
    const double scaled = 1.0 * x;
    return x * (1.0 / (1.0 + exp(-scaled)));
}
