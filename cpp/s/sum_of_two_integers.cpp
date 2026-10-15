// Add bounded signed integers with XOR and shifted carry.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
std::int64_t bitwise_add(std::int64_t a, std::int64_t b) noexcept {
    std::uint64_t left = static_cast<std::uint64_t>(a);
    std::uint64_t right = static_cast<std::uint64_t>(b);
    while (right != 0) {
        const std::uint64_t partial = left ^ right;
        right = (left & right) << 1;
        left = partial;
    }
    if (left <= static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max()))
        return static_cast<std::int64_t>(left);
    return -1 - static_cast<std::int64_t>(~left);
}
}

extern "C" std::int64_t sum_of_two_integers(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 2 || values[0] < std::numeric_limits<std::int32_t>::min() ||
        values[0] > std::numeric_limits<std::int32_t>::max() ||
        values[1] < std::numeric_limits<std::int32_t>::min() ||
        values[1] > std::numeric_limits<std::int32_t>::max()) return -1;
    return bitwise_add(values[0], values[1]);
}
