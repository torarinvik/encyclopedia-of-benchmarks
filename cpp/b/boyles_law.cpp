// Solve Boyle's law for one omitted variable, rounded to 3 decimals.
#include <cstddef>
#include <cstdint>

namespace {
constexpr double INVALID_RESULT = -1.0e300;
std::int64_t rounded_milli(std::int64_t numerator, std::int64_t denominator) {
    const std::int64_t scaled = numerator * 1000;
    std::int64_t quotient = scaled / denominator;
    const std::int64_t remainder = scaled % denominator;
    if (2 * remainder > denominator || (2 * remainder == denominator && quotient % 2 != 0)) ++quotient;
    return quotient;
}
}

extern "C" double boyles_law(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 4) return INVALID_RESULT;
    const auto target = values[0], a = values[1], b = values[2], c = values[3];
    if (target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c < 1 || c > 1000) return INVALID_RESULT;
    std::int64_t numerator, denominator;
    switch (target) {
        case 0: numerator = c * a; denominator = b; break;
        case 1: numerator = b * a; denominator = c; break;
        case 2: numerator = c * b; denominator = a; break;
        default: numerator = c * a; denominator = b; break;
    }
    return static_cast<double>(rounded_milli(numerator, denominator)) / 1000.0;
}
