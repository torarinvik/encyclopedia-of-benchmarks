// Hooke's law restoring force: -spring_constant * displacement.
#include <cstddef>
#include <cstdint>

extern "C" double hookes_law(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const std::int64_t spring_constant = values[0];
    const std::int64_t displacement = values[1];
    if (spring_constant < 1 || spring_constant > 1000 || displacement < -1000 || displacement > 1000)
        return -1.0e300;
    return (-static_cast<double>(spring_constant)) * static_cast<double>(displacement);
}
