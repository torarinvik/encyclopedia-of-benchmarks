#include <math.h>

#define INVALID_RESULT (-1.0e300)

double nth_root(double radicand, double index, double tolerance)
{
    if (!isfinite(radicand) || !isfinite(index) || !isfinite(tolerance) ||
        radicand < 0.5 || radicand > 1000.0 || index < 3.0 || index > 8.0 ||
        index != floor(index) || tolerance < 1.0e-12 || tolerance > 1.0e-3) {
        return INVALID_RESULT;
    }
    double new_approximation = radicand;
    double old_approximation = new_approximation + tolerance + 0.1;
    while (tolerance <= fabs(old_approximation - new_approximation)) {
        old_approximation = new_approximation;
        double first_summand = (index - 1.0) / index * old_approximation;
        double second_summand = radicand / (index * pow(old_approximation, index - 1.0));
        new_approximation = first_summand + second_summand;
    }
    return new_approximation;
}
