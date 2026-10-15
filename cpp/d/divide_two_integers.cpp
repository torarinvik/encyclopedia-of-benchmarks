// Truncate signed 32-bit division toward zero using doubled divisor chunks.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace { constexpr std::int64_t invalid_result = -2147483649LL; }

extern "C" std::int64_t divide_two_integers(const std::int64_t *values,
    std::size_t length) noexcept {
    if (values == nullptr || length != 2) return invalid_result;
    const auto dividend = values[0];
    const auto divisor = values[1];
    if (dividend < std::numeric_limits<std::int32_t>::min() ||
        dividend > std::numeric_limits<std::int32_t>::max() ||
        divisor < std::numeric_limits<std::int32_t>::min() ||
        divisor > std::numeric_limits<std::int32_t>::max() || divisor == 0) return invalid_result;

    auto remaining = dividend < 0 ? -dividend : dividend;
    const auto divisor_magnitude = divisor < 0 ? -divisor : divisor;
    std::int64_t quotient = 0;
    for (int shift = 31; shift >= 0; --shift) {
        if (divisor_magnitude <= (remaining >> shift)) {
            remaining -= divisor_magnitude << shift;
            quotient += std::int64_t{1} << shift;
        }
    }

    const bool negative = (dividend < 0) != (divisor < 0);
    if (negative) return quotient == 2147483648LL ? std::numeric_limits<std::int32_t>::min() : -quotient;
    return quotient > std::numeric_limits<std::int32_t>::max()
        ? std::numeric_limits<std::int32_t>::max() : quotient;
}
