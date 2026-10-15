// Fold nonnegative integers with portable Euclidean GCD.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_items = 256;
constexpr std::int64_t max_safe_integer = INT64_C(9007199254740991);

std::int64_t gcd_nonnegative(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}
}

extern "C" std::int64_t greatest_common_factor(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_items + 1) return std::numeric_limits<std::int64_t>::min();
    const auto count = values[0];
    if (count < 1 || count > static_cast<std::int64_t>(max_items) || length != static_cast<std::size_t>(count) + 1)
        return std::numeric_limits<std::int64_t>::min();
    auto result = values[1];
    if (result < 0 || result > max_safe_integer) return std::numeric_limits<std::int64_t>::min();
    for (std::size_t index = 2; index < length; ++index) {
        const auto value = values[index];
        if (value < 0 || value > max_safe_integer) return std::numeric_limits<std::int64_t>::min();
        result = gcd_nonnegative(result, value);
    }
    return result;
}
