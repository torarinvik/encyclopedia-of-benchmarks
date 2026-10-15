#include <math.h>

double cos(double x)
{
    if (!(x >= -1000000.0 && x <= 1000000.0)) return -1.0;
    const double tp = 1.0 / (2.0 * 3.141592653589793);
    x *= tp;
    x -= 0.25 + floor(x + 0.25);
    x *= 16.0 * (fabs(x) - 0.5);
    x += 0.225 * x * (fabs(x) - 1.0);
    return x;
}
