#include <cstdint>

namespace {
constexpr std::int64_t int32_min_value = -2147483648LL;
constexpr std::int64_t int32_max_value = 2147483647LL;
}

// Return the trailing-zero count of the signed 32-bit XOR.
extern "C" std::int64_t first_different_bit(std::int64_t x, std::int64_t y) noexcept
{
    if (x < int32_min_value || x > int32_max_value ||
        y < int32_min_value || y > int32_max_value) return -1;
    std::uint32_t difference = static_cast<std::uint32_t>(static_cast<std::int32_t>(x)) ^
                               static_cast<std::uint32_t>(static_cast<std::int32_t>(y));
    std::int64_t index = 0;
    while (index < 32 && (difference & 1U) == 0) {
        ++index;
        difference >>= 1;
    }
    return index;
}
