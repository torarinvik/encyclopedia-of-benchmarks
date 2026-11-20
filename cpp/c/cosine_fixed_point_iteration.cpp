#include <cmath>

extern "C" double cosine_fixed_point_iteration(double initial, double source_n) noexcept
{
    if (!std::isfinite(initial) || !std::isfinite(source_n) ||
        initial < 0.0 || initial > 2.0 || source_n < 0.0 || source_n > 64.0 ||
        std::floor(source_n) != source_n) {
        return -1.0;
    }

    const unsigned updates = static_cast<unsigned>(source_n) + 1u;
    for (unsigned iteration = 0; iteration < updates; ++iteration) {
        initial = 0.5 * (std::cos(initial) + 2.0);
    }
    return initial;
}
