/* Rectified linear unit over a bounded integer-valued binary64 domain. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_INPUT 16777216.0

double relu(double x)
{
    if (!isfinite(x) || x < -MAX_INPUT || x > MAX_INPUT || trunc(x) != x) return INVALID_RESULT;
    return x > 0.0 ? x : 0.0;
}
