/* Pinned Rust GELU approximation with its exponential tanh identity. */
#include <math.h>

#define INVALID_RESULT (-1.0e300)
#define PI_VALUE 3.14159265358979323846264338327950288
#define E_VALUE 2.71828182845904523536028747135266250

double gaussian_error_linear_unit_tanh(double x)
{
    if (!isfinite(x) || x < -100.0 || x > 100.0) return INVALID_RESULT;
    const double scale = pow(2.0 / PI_VALUE, 0.5);
    const double z = scale * (x + 0.044715 * pow(x, 3.0));
    const double tanh_value = 2.0 / (1.0 + pow(E_VALUE, -2.0 * z)) - 1.0;
    return x * 0.5 * (1.0 + tanh_value);
}
