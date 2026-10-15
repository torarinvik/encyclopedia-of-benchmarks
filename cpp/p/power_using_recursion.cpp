/* Linear recursive integer power, with a bounded exact contract. */
#include <cstdint>

static std::int64_t decode_signed(std::uint64_t value) noexcept
{
    if (value <= static_cast<std::uint64_t>(INT64_MAX)) return static_cast<std::int64_t>(value);
    return -1 - static_cast<std::int64_t>(~value);
}

static std::int64_t power_recursive(std::int64_t base, std::uint64_t exponent) noexcept
{
    if (exponent == 0) return 1;
    return base * power_recursive(base, exponent - 1);
}

extern "C" std::int64_t power_using_recursion(std::uint64_t base_encoded,
                                               std::uint64_t exponent) noexcept
{
    const std::int64_t base = decode_signed(base_encoded);
    if (base < -10 || base > 10 || exponent > 15) return INT64_MIN;
    return power_recursive(base, exponent);
}
