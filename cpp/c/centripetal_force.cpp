// Centripetal force: (mass * velocity^2) / radius.
#include <cstddef>
#include <cstdint>

extern "C" double centripetal_force(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return -1.0e300;
    const std::int64_t mass = values[0];
    const std::int64_t velocity = values[1];
    const std::int64_t radius = values[2];
    if (mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000 || radius < 1 || radius > 1000)
        return -1.0e300;
    const double velocity_squared = static_cast<double>(velocity) * static_cast<double>(velocity);
    return (static_cast<double>(mass) * velocity_squared) / static_cast<double>(radius);
}
