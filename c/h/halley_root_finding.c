#include <math.h>

double halley_root_finding(double initial_x, double iteration_count)
{
    if (!isfinite(initial_x) || !isfinite(iteration_count) ||
        initial_x < 0.5 || initial_x > 2.0 ||
        iteration_count < 0.0 || iteration_count > 8.0 ||
        floor(iteration_count) != iteration_count) {
        return -1.0;
    }

    for (unsigned i = 0; i < (unsigned)iteration_count; ++i) {
        const double value = initial_x * initial_x * initial_x - 2.0;
        const double first = 3.0 * initial_x * initial_x;
        const double second = 6.0 * initial_x;
        const double denominator = 2.0 * first * first - value * second;
        if (denominator == 0.0 || !isfinite(denominator)) return -1.0;
        initial_x -= (2.0 * value * first) / denominator;
        if (!isfinite(initial_x)) return -1.0;
    }
    return initial_x;
}
