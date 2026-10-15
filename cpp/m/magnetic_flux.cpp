// Magnetic flux rounded to one decimal place.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double magnetic_flux(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return -1.0e300;
    const auto magnetic_field = values[0];
    const auto area = values[1];
    const auto angle = values[2];
    if (magnetic_field < 0 || magnetic_field > 10'000 || area < 0 || area > 10'000 ||
        (angle != 0 && angle != 60 && angle != 90 && angle != 120 && angle != 180)) return -1.0e300;
    constexpr double pi = 3.14159265358979323846;
    const double radians = static_cast<double>(angle) * (pi / 180.0);
    const double flux = static_cast<double>(magnetic_field) * static_cast<double>(area) * std::cos(radians);
    return std::round(flux * 10.0) / 10.0;
}
