// Solve one missing quantity in the ideal-plate Casimir force equation.
#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" double casimir_effect(const std::int64_t *values, std::size_t length) noexcept {
    constexpr double invalid = -1.0e300;
    constexpr double hbar = 1.054571817e-34;
    constexpr double c = 3.0e8;
    constexpr double pi = 3.14159265358979323846;
    if (values == nullptr || length != 3) return invalid;
    const auto force_units = values[0];
    const auto area_units = values[1];
    const auto distance_units = values[2];
    if (force_units < 0 || force_units > 1'000'000 || area_units < 0 || area_units > 1'000'000 ||
        distance_units < 0 || distance_units > 1'000'000) return invalid;
    const int zeros = (force_units == 0) + (area_units == 0) + (distance_units == 0);
    if (zeros != 1) return invalid;
    const double force = static_cast<double>(force_units) * 1.0e-12;
    const double area = static_cast<double>(area_units) * 1.0e-6;
    const double distance = static_cast<double>(distance_units) * 1.0e-6;
    if (force_units == 0)
        return (hbar * c * std::pow(pi, 2.0) * area) / (240.0 * std::pow(distance, 4.0));
    if (area_units == 0)
        return (240.0 * force * std::pow(distance, 4.0)) / (hbar * c * std::pow(pi, 2.0));
    return std::pow((hbar * c * std::pow(pi, 2.0) * area) / (240.0 * force), 0.25);
}
