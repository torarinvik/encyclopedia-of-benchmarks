// Reynolds number: density * abs(velocity) * diameter / viscosity.
#include <cstddef>
#include <cstdint>

extern "C" double reynolds_number(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return -1.0e300;
    const std::int64_t density = values[0];
    const std::int64_t velocity = values[1];
    const std::int64_t diameter = values[2];
    const std::int64_t viscosity = values[3];
    if (density < 1 || density > 1000 || velocity < -1000 || velocity > 1000 ||
        diameter < 1 || diameter > 1000 || viscosity < 1 || viscosity > 1000)
        return -1.0e300;
    const std::int64_t speed = velocity < 0 ? -velocity : velocity;
    return (((static_cast<double>(density) * static_cast<double>(speed)) * static_cast<double>(diameter)) /
            static_cast<double>(viscosity));
}
