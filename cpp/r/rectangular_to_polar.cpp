#include <cmath>
#include <cstdint>

static constexpr double INVALID_RESULT = -1.0e300;
static constexpr double DEGREE_FACTOR = 57.2957795130823208768;

static double round_to_two_decimals_away(double value) {
    if (value == 0.0) return value;
    const double scaled = value * 100.0;
    const double units = std::trunc(scaled < 0.0 ? scaled - 0.5 : scaled + 0.5);
    if (units == 0.0 && std::signbit(value)) return -0.0;
    return units / 100.0;
}

extern "C" double rectangular_to_polar(double real, double imag, double component) {
    if (!std::isfinite(real) || !std::isfinite(imag) || !std::isfinite(component) ||
        real < -1000000.0 || real > 1000000.0 || imag < -1000000.0 || imag > 1000000.0 ||
        (component != 0.0 && component != 1.0)) return INVALID_RESULT;
    if (component == 0.0) return round_to_two_decimals_away(std::sqrt(real * real + imag * imag));
    return round_to_two_decimals_away(std::atan2(imag, real) * DEGREE_FACTOR);
}
