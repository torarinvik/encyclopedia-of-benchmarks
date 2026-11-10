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
    std::uint64_t total = 0, largest_biased_value = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::uint64_t value = static_cast<std::uint64_t>(values[index]);
        const std::uint64_t biased = value + max_value;
        largest_biased_value = biased > largest_biased_value ? biased : largest_biased_value;
        total += value;
    }
    if (largest_biased_value > 2 * max_value) return -1;
    const std::int64_t signed_total = static_cast<std::int64_t>(total);
    const std::int64_t threshold = signed_total / 2 + (signed_total > 0 && signed_total % 2 != 0);
    std::uint64_t prefix = 0;
    std::int64_t ways = 0;
    for (std::size_t index = 0; index < length - 1; ++index) {
        prefix += static_cast<std::uint64_t>(values[index]);
        if (static_cast<std::int64_t>(prefix) >= threshold) ways++;
    }
    return ways;
}
