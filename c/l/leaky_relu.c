/* Leaky ReLU for one vector element and a caller-supplied slope. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_INPUT 1000000.0

double leaky_relu(double x, double alpha)
{
    if (!isfinite(x) || !isfinite(alpha) || x < -MAX_INPUT || x > MAX_INPUT ||
        alpha < -MAX_INPUT || alpha > MAX_INPUT) return INVALID_RESULT;
    return x < 0.0 ? x * alpha : x;
}
