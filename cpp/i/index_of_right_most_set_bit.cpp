#include <cstdint>

namespace {
constexpr std::int64_t INT32_MIN_VALUE = -INT64_C(2147483648);
constexpr std::int64_t INT32_MAX_VALUE = INT64_C(2147483647);
}

// Zero-based trailing set-bit index using the Java magnitude behavior.
extern "C" std::int64_t index_of_right_most_set_bit(std::int64_t value) noexcept
{
    if (value < INT32_MIN_VALUE || value > INT32_MAX_VALUE || value == 0) return -1;
    std::uint64_t magnitude = static_cast<std::uint64_t>(value < 0 ? -value : value);
    std::int64_t index = 0;
    while ((magnitude & UINT64_C(1)) == 0) {
        magnitude >>= 1;
        ++index;
    }
    return index;
}
