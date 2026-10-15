// Buoyant force: fluid density * gravity * displaced volume.
#include <cstddef>
#include <cstdint>

extern "C" double archimedes_principle_of_buoyant_force(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const std::int64_t fluid_density = values[0];
    const std::int64_t volume = values[1];
    if (fluid_density < 1 || fluid_density > 1000 || volume < 1 || volume > 1000)
        return -1.0e300;
    return (static_cast<double>(fluid_density) * 9.80665) * static_cast<double>(volume);
}
