// Bragg diffraction angle, rounded to one decimal degree.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
constexpr double PI = 3.141592653589793238462643383279502884;
double round_one_even(double value) {
    const double scaled = value * 10.0;
    const double lower = std::floor(scaled);
    const double fraction = scaled - lower;
    auto rounded = static_cast<std::int64_t>(lower);
    if (fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0)) ++rounded;
    return static_cast<double>(rounded) / 10.0;
}
}

extern "C" double bragg_angle(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return INVALID_RESULT;
    const auto distance = values[0], order = values[1], wavelength = values[2];
    if (distance < 1 || distance > 1000000 || order < -1000 || order > 1000 || wavelength < 0 || wavelength > 1000000) return INVALID_RESULT;
    const double sine = (static_cast<double>(order) * static_cast<double>(wavelength)) / (2.0 * static_cast<double>(distance));
    if (sine < -1.0 || sine > 1.0) return INVALID_RESULT;
    const double degrees = std::asin(sine) * (180.0 / PI);
    return round_one_even(degrees);
}
