// Classical kinetic energy: 0.5 * mass * abs(velocity)^2.
#include <cstddef>
#include <cstdint>

extern "C" double kinetic_energy(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const std::int64_t mass = values[0];
    const std::int64_t velocity = values[1];
    if (mass < 0 || mass > 1000 || velocity < -1000 || velocity > 1000)
        return -1.0e300;
    const std::int64_t speed = velocity < 0 ? -velocity : velocity;
    return ((0.5 * static_cast<double>(mass)) * static_cast<double>(speed)) * static_cast<double>(speed);
}
