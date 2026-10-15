#include <math.h>

#define INVALID_RESULT (-1.0e300)

double softplus(double x)
{
    if (x != x || x < -100.0 || x > 100.0) return INVALID_RESULT;
    return log(1.0 + exp(x));
}
