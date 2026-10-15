// Gravitational potential energy: mass * standard gravity * height.
#include <cstddef>
#include <cstdint>

extern "C" double potential_energy(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const std::int64_t mass = values[0];
    const std::int64_t height = values[1];
    if (mass < 0 || mass > 1000 || height < 0 || height > 1000)
        return -1.0e300;
    return (static_cast<double>(mass) * 9.80665) * static_cast<double>(height);
}
