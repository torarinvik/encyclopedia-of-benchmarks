// Convert a bounded speed between five source-defined units.
#include <cmath>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0;

double round_two_php(double value) noexcept {
    return std::floor(value * 100.0 + 0.5) / 100.0;
}
}

extern "C" double speed_conversion(double speed, double route) noexcept {
    if (!std::isfinite(speed) || !std::isfinite(route) || speed < 0.0 || speed > 1000000.0 ||
        route < 0.0 || route > 24.0 || std::floor(route) != route) return invalid_result;
    constexpr double factors[5] = {1.609344, 1.0, 3.6, 1.097, 1.852};
    constexpr double inverse_factors[5] = {0.6213712, 1.0, 0.277778, 0.911344, 0.539957};
    const int unit_from = static_cast<int>(route) / 5;
    const int unit_to = static_cast<int>(route) % 5;
    return round_two_php(speed * factors[unit_from] * inverse_factors[unit_to]);
}
