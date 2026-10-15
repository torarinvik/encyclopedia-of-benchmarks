// Solve impedance, resistance, or reactance from the other two values.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double electrical_impedance(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return INVALID_RESULT;
    const auto resistance = values[0];
    const auto reactance = values[1];
    const auto impedance = values[2];
    if (resistance < 0 || resistance > 1000 || reactance < 0 || reactance > 1000 || impedance < 0 || impedance > 1000) return INVALID_RESULT;
    const int zeros = (resistance == 0) + (reactance == 0) + (impedance == 0);
    if (zeros != 1) return INVALID_RESULT;
    const double r = static_cast<double>(resistance);
    const double x = static_cast<double>(reactance);
    const double z = static_cast<double>(impedance);
    const double radicand = resistance == 0 ? z * z - x * x
                            : reactance == 0 ? z * z - r * r
                                             : r * r + x * x;
    return radicand < 0.0 ? INVALID_RESULT : std::sqrt(radicand);
}
