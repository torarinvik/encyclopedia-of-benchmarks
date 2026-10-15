/* Binary step over a bounded finite binary64 domain. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)

double binary_step(double x)
{
    if (!isfinite(x) || x < -1000000.0 || x > 1000000.0) return INVALID_RESULT;
    return x >= 0.0 ? 1.0 : 0.0;
}
