// Malus's law: I0 * cos(radians(angle))^2.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double PI = 3.141592653589793238462643383279502884; }

extern "C" double malus_law(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const std::int64_t initial_intensity = values[0];
    const std::int64_t angle = values[1];
    if (initial_intensity < 0 || initial_intensity > 1000 || angle < 0 || angle > 360)
        return -1.0e300;
    const double radians = (static_cast<double>(angle) * PI) / 180.0;
    const double cosine = std::cos(radians);
    return static_cast<double>(initial_intensity) * (cosine * cosine);
}
