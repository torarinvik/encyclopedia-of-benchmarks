#include <math.h>

double modified_newton_multiple_root(double initial_x, double iteration_count)
{
    if (!isfinite(initial_x) || !isfinite(iteration_count) ||
        initial_x < 1.0 || initial_x > 2.0 || iteration_count < 0.0 ||
        iteration_count > 8.0 || floor(iteration_count) != iteration_count) {
        return -1.0;
    }

    for (unsigned i = 0; i < (unsigned)iteration_count; ++i) {
        if (initial_x == 1.0) break;
        const double offset = initial_x - 1.0;
        const double value = offset * offset * (initial_x + 2.0);
        const double derivative = 3.0 * offset * (initial_x + 1.0);
        if (derivative == 0.0 || !isfinite(derivative)) return -1.0;
        initial_x -= 2.0 * (value / derivative);
        if (!isfinite(initial_x) || initial_x < 1.0 || initial_x > 2.0) return -1.0;
    }
    return initial_x;
}
