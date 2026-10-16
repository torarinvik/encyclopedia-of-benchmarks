#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define PI 3.14159265358979323846264338327950288

double gaussian(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t x = values[0], mu = values[1], sigma = values[2];
    if (x < -100 || x > 100 || mu < -100 || mu > 100 || sigma < 1 || sigma > 100) return INVALID_RESULT;
    const int64_t difference = x - mu;
    const int64_t sigma_squared = sigma * sigma;
    const double normalization = 1.0 / sqrt(2.0 * PI * (double)sigma_squared);
    const double exponent = -(double)(difference * difference) / (double)(2 * sigma_squared);
    return normalization * exp(exponent);
}
