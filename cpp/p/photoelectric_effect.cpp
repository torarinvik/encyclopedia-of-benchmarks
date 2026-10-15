// Photoelectric maximum electron kinetic energy in electronvolts.
#include <cstddef>
#include <cstdint>

constexpr double PLANCK_EV = 4.1357e-15;
constexpr double INVALID_RESULT = -1.0e300;

extern "C" double photoelectric_effect(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return INVALID_RESULT;
    const auto frequency = values[0];
    const auto work_function = values[1];
    if (frequency < 0 || frequency > INT64_C(1000000000000000000) || work_function < 0 || work_function > 1000)
        return INVALID_RESULT;
    const double photon_energy = PLANCK_EV * static_cast<double>(frequency);
    const double energy_difference = photon_energy - static_cast<double>(work_function);
    return energy_difference > 0.0 ? energy_difference : 0.0;
}
