#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 256;
std::int64_t find_min_range(const std::int64_t* values, std::size_t low, std::size_t high) {
    if (low == high) return values[low];
    const auto middle = low + (high - low) / 2;
    const auto left = find_min_range(values, low, middle);
    const auto right = find_min_range(values, middle + 1, high);
    return left <= right ? left : right;
}
}
extern "C" std::int64_t find_min_recursion(const std::int64_t* values, std::size_t length) noexcept {
    if (!values || length == 0 || length > max_length) return -1;
    for (std::size_t i = 0; i < length; ++i) if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;
    return find_min_range(values, 0, length - 1);
}
