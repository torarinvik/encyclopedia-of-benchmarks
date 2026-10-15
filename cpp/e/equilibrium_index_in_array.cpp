// Return the first index with equal left and right sums.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 1024;
constexpr std::int64_t min_i32 = -2147483648LL;
constexpr std::int64_t max_i32 = 2147483647LL;
}

extern "C" std::int64_t equilibrium_index_in_array(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > max_length + 1) return -2;
    const std::int64_t n = values[0];
    if (n < 0 || n > static_cast<std::int64_t>(max_length) || length != static_cast<std::size_t>(n) + 1) return -2;
    std::int64_t total = 0;
    for (std::size_t i = 1; i < length; ++i) {
        if (values[i] < min_i32 || values[i] > max_i32) return -2;
        total += values[i];
    }
    std::int64_t left = 0;
    for (std::int64_t i = 0; i < n; ++i) {
        total -= values[static_cast<std::size_t>(i) + 1];
        if (left == total) return i;
        left += values[static_cast<std::size_t>(i) + 1];
    }
    return -1;
}
