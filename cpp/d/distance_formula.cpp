// Compute the Euclidean distance with the pinned Java coordinate expression.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double distance_formula(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return INVALID_RESULT;
    for (std::size_t i = 0; i < 4; ++i)
        if (values[i] < -1000000 || values[i] > 1000000) return INVALID_RESULT;
    const double dx = static_cast<double>(values[2] - values[0]);
    const double dy = static_cast<double>(values[3] - values[0]);
    return std::sqrt(dx * dx + dy * dy);
}
