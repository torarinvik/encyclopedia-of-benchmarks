/* Hyperbolic tangent using the normalized logistic identity. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double tanh(double x)
{
    if (!isfinite(x) || x < -10.0 || x > 10.0) return INVALID_RESULT;
    return (2.0 / (1.0 + exp(-2.0 * x))) - 1.0;
}
