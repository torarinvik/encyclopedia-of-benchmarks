// Compute a regular dodecahedron's area or volume from its edge length.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double dodecahedron(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return INVALID_RESULT;
    const auto edge = values[0];
    const auto quantity = values[1];
    if (edge < 1 || edge > 1000000 || (quantity != 0 && quantity != 1)) return INVALID_RESULT;

    const double root_five = std::sqrt(5.0);
    if (quantity == 0) {
        const double area_factor = 3.0 * std::sqrt(25.0 + 10.0 * root_five);
        return area_factor * static_cast<double>(edge * edge);
    }
    const double volume_factor = (15.0 + 7.0 * root_five) / 4.0;
    return volume_factor * static_cast<double>(edge * edge * edge);
}
