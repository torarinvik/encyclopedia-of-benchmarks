// Inductive reactance relation over a bounded integer-valued domain.
#include <cstddef>
#include <cstdint>

namespace { constexpr double PI = 3.14159265358979323846; constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double ind_reactance(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 3) return INVALID_RESULT;
    const auto inductance = values[0];
    const auto frequency = values[1];
    const auto reactance = values[2];
    if (inductance < 0 || inductance > 1000 || frequency < 0 || frequency > 1000 || reactance < 0 || reactance > 1000) return INVALID_RESULT;
    const int zeros = (inductance == 0) + (frequency == 0) + (reactance == 0);
    if (zeros != 1) return INVALID_RESULT;
    if (inductance == 0) return static_cast<double>(reactance) / (2.0 * PI * static_cast<double>(frequency));
    if (frequency == 0) return static_cast<double>(reactance) / (2.0 * PI * static_cast<double>(inductance));
    return 2.0 * PI * static_cast<double>(frequency) * static_cast<double>(inductance);
}
