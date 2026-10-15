/* Squareplus activation for one element of the source vector. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double squareplus(double x, double beta)
{
    if (!(isfinite(x) && isfinite(beta) && x >= -10000.0 && x <= 10000.0 && beta >= 0.25 && beta <= 10000.0)) return INVALID_RESULT;
    return (x + sqrt(x * x + beta)) / 2.0;
}
