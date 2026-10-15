/* Rust-canonical ELU source expression for one vector element. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define X_MIN (-100.0)
#define X_MAX 100.0
#define ALPHA_MAX 1000000.0

double exponential_linear_unit(double x, double alpha)
{
    if (!isfinite(x) || !isfinite(alpha) || x < X_MIN || x > X_MAX ||
        alpha < -ALPHA_MAX || alpha > ALPHA_MAX) return INVALID_RESULT;
    return x < 0.0 ? x * (alpha * (exp(x) - 1.0)) : x;
}
