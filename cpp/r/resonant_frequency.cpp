// LC resonant frequency over bounded integer-valued inputs.
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace { constexpr double PI = 3.14159265358979323846; constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double resonant_frequency(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2) return INVALID_RESULT;
    const auto inductance = values[0];
    const auto capacitance = values[1];
    if (inductance < 1 || inductance > 1000 || capacitance < 1 || capacitance > 1000) return INVALID_RESULT;
    return 1.0 / (2.0 * PI * std::sqrt(static_cast<double>(inductance) * static_cast<double>(capacitance)));
}
