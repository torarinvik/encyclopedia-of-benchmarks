// Terminal velocity with standard gravity and bounded positive inputs.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double terminal_velocity(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return -1.0e300;
    const std::int64_t mass = values[0];
    const std::int64_t density = values[1];
    const std::int64_t area = values[2];
    const std::int64_t drag_coefficient = values[3];
    if (mass < 1 || mass > 1000 || density < 1 || density > 1000 || area < 1 || area > 1000 ||
        drag_coefficient < 1 || drag_coefficient > 1000)
        return -1.0e300;
    const double numerator = (2.0 * static_cast<double>(mass)) * 9.80665;
    const double denominator = (static_cast<double>(density) * static_cast<double>(area)) * static_cast<double>(drag_coefficient);
    return std::sqrt(numerator / denominator);
}
