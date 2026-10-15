#include <cstdint>

namespace {
constexpr std::int64_t INT32_MIN_VALUE = -2147483648LL;
constexpr std::int64_t INT32_MAX_VALUE = 2147483647LL;
}

// Return whether the signed 32-bit XOR has its sign bit set.
extern "C" std::int64_t numbers_different_signs(std::int64_t left, std::int64_t right) noexcept
{
    if (left < INT32_MIN_VALUE || left > INT32_MAX_VALUE ||
        right < INT32_MIN_VALUE || right > INT32_MAX_VALUE) return -1;
    const auto left_value = static_cast<std::int32_t>(left);
    const auto right_value = static_cast<std::int32_t>(right);
    return (left_value ^ right_value) < 0 ? 1 : 0;
}
