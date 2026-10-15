#include <cmath>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;
constexpr double pi = 3.141592653589793238462643383279502884;

double round_two_even(double value)
{
    const double scaled = value * 100.0;
    const double lower = std::floor(scaled);
    const double fraction = scaled - lower;
    auto rounded = static_cast<std::int64_t>(lower);
    if (fraction > 0.5 || (fraction == 0.5 && rounded % 2 != 0)) ++rounded;
    return static_cast<double>(rounded) / 100.0;
}
}

extern "C" double snells_law(double n1, double n2, double incident_angle_degrees) noexcept
{
    if (!(n1 >= 0.5 && n1 <= 2.5) || !(n2 >= 0.5 && n2 <= 2.5) ||
        !(incident_angle_degrees >= -90.0 && incident_angle_degrees <= 90.0)) return invalid_result;
    const double incident_angle_radians = incident_angle_degrees * (pi / 180.0);
    const double refraction_sine = (n1 / n2) * std::sin(incident_angle_radians);
    const double scale = std::fmax(std::abs(refraction_sine), 1.0);
    if (std::abs(refraction_sine - 1.0) <= 1.0e-9 * scale) return 90.0;
    if (std::abs(refraction_sine + 1.0) <= 1.0e-9 * scale) return -90.0;
    if (!(refraction_sine >= -1.0 && refraction_sine <= 1.0)) return invalid_result;
    const double refraction_angle_degrees = std::asin(refraction_sine) * (180.0 / pi);
    return round_two_even(refraction_angle_degrees);
}
