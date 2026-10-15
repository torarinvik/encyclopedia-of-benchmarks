#include <math.h>

#define INVALID_RESULT (-1.0e300)

double softsign(double x)
{
    if (x != x || x < -1.0e100 || x > 1.0e100) return INVALID_RESULT;
    return x / (1.0 + fabs(x));
}
