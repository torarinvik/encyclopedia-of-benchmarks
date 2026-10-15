// RMS molecular speed: (3 * R * temperature / molar_mass) ** 0.5.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double rms_speed_of_molecule(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return -1.0e300;
    const std::int64_t temperature = values[0];
    const std::int64_t molar_mass = values[1];
    if (temperature < 0 || temperature > 1000 || molar_mass < 1 || molar_mass > 1000)
        return -1.0e300;
    const double numerator = (3.0 * 8.3144598) * static_cast<double>(temperature);
    return std::pow(numerator / static_cast<double>(molar_mass), 0.5);
}
