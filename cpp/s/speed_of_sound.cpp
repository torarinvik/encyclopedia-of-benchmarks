// Speed of sound in a fluid: (bulk modulus / density) ** 0.5.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double speed_of_sound(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const std::int64_t density = values[0];
    const std::int64_t bulk_modulus = values[1];
    if (density < 1 || density > 1000 || bulk_modulus < 1 || bulk_modulus > 1000000000)
        return -1.0e300;
    return std::pow(static_cast<double>(bulk_modulus) / static_cast<double>(density), 0.5);
}
