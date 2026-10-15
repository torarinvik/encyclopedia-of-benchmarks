// Convert a bounded speed between four source-defined units.
#include <cmath>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0;

double round_three_even(double value) noexcept {
    const double lower = std::floor(value * 1000.0);
    const double midpoint = lower + 0.5;
    const double exact_side = std::fma(value, 1000.0, -midpoint);
    auto rounded = static_cast<std::int64_t>(lower);
    if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) ++rounded;
    return static_cast<double>(rounded) / 1000.0;
}
}

extern "C" double speed_conversions(double speed, double route) noexcept {
    if (!std::isfinite(speed) || !std::isfinite(route) || speed < 0.0 || speed > 1000000.0 ||
        route < 0.0 || route > 15.0 || std::floor(route) != route) return invalid_result;
    constexpr double factors[4] = {1.0, 3.6, 1.609344, 1.852};
    constexpr double inverse_factors[4] = {1.0, 0.277777778, 0.621371192, 0.539956803};
    const int unit_from = static_cast<int>(route) / 4;
    const int unit_to = static_cast<int>(route) % 4;
    return round_three_even(speed * factors[unit_from] * inverse_factors[unit_to]);
}
