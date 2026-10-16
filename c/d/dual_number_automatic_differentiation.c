/* Nth derivative of x^power via truncated dual-number coefficients. */
#include <stdint.h>

#define INVALID_RESULT (-1e300)
#define MAX_POWER 8

double dual_number_automatic_differentiation(double position, double power, double order)
{
    if (!(position >= -1.0 && position <= 1.0) || !(power >= 0.0 && power <= MAX_POWER) ||
        !(order >= 0.0 && order <= MAX_POWER)) return INVALID_RESULT;
    const int exponent = (int)power, derivative_order = (int)order;
    if (power != (double)exponent || order != (double)derivative_order || derivative_order > exponent)
        return INVALID_RESULT;

    double coefficients[MAX_POWER + 1] = {0.0};
    coefficients[0] = 1.0;
    for (int step = 0; step < exponent; ++step) {
        double next[MAX_POWER + 1] = {0.0};
        next[0] = coefficients[0] * position;
        for (int degree = 1; degree <= step + 1; ++degree)
            next[degree] = coefficients[degree] * position + coefficients[degree - 1];
        for (int degree = 0; degree <= MAX_POWER; ++degree) coefficients[degree] = next[degree];
    }
    double result = coefficients[derivative_order];
    for (int factor = 2; factor <= derivative_order; ++factor) result *= (double)factor;
    return result;
}
