#include <cstdint>

namespace {
constexpr std::uint64_t MAX_NUM = UINT64_C(2147483647);
constexpr std::int64_t INVALID_RESULT = -1;
}

extern "C" std::int64_t find_nth_bit(std::uint64_t num, std::uint64_t n) noexcept
{
    if (num > MAX_NUM || n < 1 || n > 31) return INVALID_RESULT;
    const std::int32_t value = static_cast<std::int32_t>(num);
    const std::int32_t shift = static_cast<std::int32_t>(n - 1);
    return (value & (INT32_C(1) << shift)) >> shift;
}
