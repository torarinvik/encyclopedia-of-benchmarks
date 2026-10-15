// Escape velocity with the source's three-decimal result rounding.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
double round_three_even(double value) {
    const double scaled = value * 1000.0;
    const double lower = std::floor(scaled);
    const double midpoint = lower + 0.5;
    const double exact_side = std::fma(value, 1000.0, -midpoint);
    auto rounded = static_cast<std::int64_t>(lower);
    if (exact_side > 0.0 || (exact_side == 0.0 && rounded % 2 != 0)) ++rounded;
    return static_cast<double>(rounded) / 1000.0;
}
}

extern "C" double escape_velocity(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return INVALID_RESULT;
    const auto mass = values[0], radius = values[1];
    if (mass < 0 || mass > INT64_C(1000000000000000) || radius < 1 || radius > INT64_C(1000000000)) return INVALID_RESULT;
    const double velocity = std::sqrt(2.0 * 6.67430e-11 * static_cast<double>(mass) / static_cast<double>(radius));
    return round_three_even(velocity);
}
