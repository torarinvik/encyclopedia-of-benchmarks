/* Port of the pinned Go sine wrapper and its Bhaskara-style cosine formula. */
#include <math.h>

double sin_radians(double radians)
{
    if (!(radians >= -1000000.0 && radians <= 1000000.0)) return -1.0;
    double x = (3.141592653589793 / 2.0) - radians;
    const double tp = 1.0 / (2.0 * 3.141592653589793);
    x *= tp;
    x -= 0.25 + floor(x + 0.25);
    x *= 16.0 * (fabs(x) - 0.5);
    x += 0.225 * x * (fabs(x) - 1.0);
    return x;
}
