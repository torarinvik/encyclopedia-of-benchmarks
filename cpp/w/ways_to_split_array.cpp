// Count positions where the prefix sum is at least the remaining suffix sum.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 100000;
constexpr std::int64_t max_value = 100000;
}

extern "C" std::int64_t ways_to_split_array(const std::int64_t *values,
                                             std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_length) return -1;
    std::int64_t total_sum = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < -max_value || values[index] > max_value) return -1;
        total_sum += values[index];
    }
    std::int64_t prefix_sum = 0;
    std::int64_t ways = 0;
    for (std::size_t index = 0; index + 1 < length; ++index) {
        prefix_sum += values[index];
        if (prefix_sum >= total_sum - prefix_sum) ++ways;
    }
    return ways;
}
