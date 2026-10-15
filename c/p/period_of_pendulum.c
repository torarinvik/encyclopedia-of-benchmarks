/* Small-amplitude pendulum period: 2 * pi * sqrt(length / g). */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define PI 3.141592653589793238462643383279502884

double period_of_pendulum(const int64_t *values, size_t length)
{
    if (values == NULL || length != 1) return INVALID_RESULT;
    const int64_t pendulum_length = values[0];
    if (pendulum_length < 0 || pendulum_length > 1000) return INVALID_RESULT;
    const double root = pow((double)pendulum_length / 9.80665, 0.5);
    return (2.0 * PI) * root;
}
