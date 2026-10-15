#include <math.h>

#define INVALID_RESULT (-1.0e300)

double sigmoid(double x)
{
    if (x != x || x < -20.0 || x > 20.0) return INVALID_RESULT;
    return 1.0 / (1.0 + exp(-x));
}
