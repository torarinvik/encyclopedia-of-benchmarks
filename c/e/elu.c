/* Conventional exponential linear unit from the pinned MATLAB formula. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define ALPHA_MAX 1000000.0

double elu(double x, double alpha)
{
    if (!isfinite(x) || !isfinite(alpha) || x < -100.0 || x > 100.0 ||
        alpha < -ALPHA_MAX || alpha > ALPHA_MAX) return INVALID_RESULT;
    return x < 0.0 ? alpha * (exp(x) - 1.0) : x;
}
