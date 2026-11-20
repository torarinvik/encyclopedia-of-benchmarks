#include <cmath>

extern "C" double modified_newton_multiple_root(double initial_x, double iteration_count) noexcept
{
    if (!std::isfinite(initial_x) || !std::isfinite(iteration_count) ||
        initial_x < 1.0 || initial_x > 2.0 || iteration_count < 0.0 ||
        iteration_count > 8.0 || std::floor(iteration_count) != iteration_count) {
        return -1.0;
    }

    for (unsigned i = 0; i < static_cast<unsigned>(iteration_count); ++i) {
        if (initial_x == 1.0) break;
        const double offset = initial_x - 1.0;
        const double value = offset * offset * (initial_x + 2.0);
        const double derivative = 3.0 * offset * (initial_x + 1.0);
        if (derivative == 0.0 || !std::isfinite(derivative)) return -1.0;
        initial_x -= 2.0 * (value / derivative);
        if (!std::isfinite(initial_x) || initial_x < 1.0 || initial_x > 2.0) return -1.0;
    }
    return initial_x;
}
