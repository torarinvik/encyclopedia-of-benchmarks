#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define PI 3.14159265358979323846264338327950288

static double factorial(int64_t n) { double result = 1.0; for (int64_t i = 2; i <= n; ++i) result *= (double)i; return result; }

double maclaurin_series(const int64_t *values, size_t length)
{
    if (values == NULL || length != 3) return INVALID_RESULT;
    const int64_t mode = values[0], theta_input = values[1], accuracy = values[2];
    if ((mode != 0 && mode != 1) || theta_input < -10 || theta_input > 10 || accuracy < 1 || accuracy > 30) return INVALID_RESULT;
    double theta = (double)theta_input;
    const double div = floor(theta / (2.0 * PI));
    theta = theta - 2.0 * div * PI;
    double sum = 0.0;
    for (int64_t r = 0; r < accuracy; ++r) {
        const int64_t exponent = mode == 0 ? 2 * r + 1 : 2 * r;
        const double sign = (r % 2 == 0) ? 1.0 : -1.0;
        sum += sign * pow(theta, (double)exponent) / factorial(exponent);
    }
    return sum;
}
