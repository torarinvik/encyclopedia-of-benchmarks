#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t speed_of_light = 299792458;
constexpr double invalid_result = -1.0e300;
}

extern "C" double relativistic_kinetic_energy(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return invalid_result;
    const std::int64_t mass = values[0];
    const std::int64_t velocity = values[1];
    if (mass < 0 || mass > 1000000 || velocity < -(speed_of_light - 1) || velocity > speed_of_light - 1)
        return invalid_result;
    const double gamma = 1.0 / std::sqrt(1.0 - (static_cast<double>(velocity * velocity) /
        static_cast<double>(speed_of_light * speed_of_light)));
    return (gamma - 1.0) * static_cast<double>(mass) * static_cast<double>(speed_of_light * speed_of_light);
}
