/* Bounded Gauss-Legendre quadrature using the pinned Fortran tables. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)

double gaussian_legendre(const int64_t *values, size_t length)
{
    if (values == NULL || length != 7) return INVALID_RESULT;
    if (values[0] < 1 || values[0] > 5 || values[1] < -5000 || values[1] > 5000 ||
        values[2] < -5000 || values[2] > 5000) return INVALID_RESULT;
    for (size_t i = 3; i < 7; ++i)
        if (values[i] < -10000 || values[i] > 10000) return INVALID_RESULT;

    const int order = (int)values[0];
    double nodes[5] = {0.0}, weights[5] = {0.0};
    switch (order) {
    case 1: nodes[0] = 0.0; weights[0] = 2.0; break;
    case 2:
        nodes[0] = -0.5773502692; nodes[1] = 0.5773502692;
        weights[0] = 1.0; weights[1] = 1.0; break;
    case 3:
        nodes[0] = -0.7745966692; nodes[1] = 0.0; nodes[2] = 0.7745966692;
        weights[0] = 0.5555555556; weights[1] = 0.8888888889; weights[2] = 0.5555555556; break;
    case 4:
        nodes[0] = -0.8611363116; nodes[1] = -0.3399810436;
        nodes[2] = 0.3399810436; nodes[3] = 0.8611363116;
        weights[0] = 0.3478548451; weights[1] = 0.6521451549;
        weights[2] = 0.6521451549; weights[3] = 0.3478548451; break;
    default:
        nodes[0] = -0.9061798459; nodes[1] = -0.5384693101; nodes[2] = 0.0;
        nodes[3] = 0.5384693101; nodes[4] = 0.9061798459;
        weights[0] = 0.2369268851; weights[1] = 0.4786286705;
        weights[2] = 0.5688888889; weights[3] = 0.4786286705;
        weights[4] = 0.2369268851;
    }

    const double a = (double)values[1] / 1000.0;
    const double b = (double)values[2] / 1000.0;
    const double c0 = (double)values[3] / 1000.0, c1 = (double)values[4] / 1000.0;
    const double c2 = (double)values[5] / 1000.0, c3 = (double)values[6] / 1000.0;
    double weighted_sum = 0.0;
    for (int i = 0; i < order; ++i) {
        const double x = (b + a) / 2.0 + (b - a) * nodes[i] / 2.0;
        const double x2 = x * x, x3 = x2 * x;
        const double function_value = c0 + c1 * x + c2 * x2 + c3 * x3;
        weighted_sum += weights[i] * function_value;
    }
    return weighted_sum * (b - a) / 2.0;
}
