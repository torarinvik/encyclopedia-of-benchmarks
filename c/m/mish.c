/* Mish activation for one element of the source vector. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double mish(double x)
{
    if (!isfinite(x) || x < -20.0 || x > 20.0) return INVALID_RESULT;
    const double softplus = log(1.0 + exp(x));
    return x * tanh(softplus);
}
