// Return the earliest split with the smallest difference of integer averages.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
constexpr std::size_t max_length = 100000;
constexpr std::int64_t max_value = 100000;
}

extern "C" std::int64_t minimum_average_difference(const std::int64_t *values,
                                                    std::size_t length) noexcept {
    if (values == nullptr || length == 0 || length > max_length) return -1;
    std::int64_t total_sum = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > max_value) return -1;
        total_sum += values[index];
    }
    std::int64_t prefix_sum = 0;
    std::int64_t best_difference = std::numeric_limits<std::int64_t>::max();
    std::size_t best_index = 0;
    for (std::size_t index = 0; index < length; ++index) {
        prefix_sum += values[index];
        const auto left_average = prefix_sum / static_cast<std::int64_t>(index + 1);
        const auto suffix_length = length - index - 1;
        const auto right_average = suffix_length == 0 ? 0
            : (total_sum - prefix_sum) / static_cast<std::int64_t>(suffix_length);
        const auto difference = left_average >= right_average
            ? left_average - right_average : right_average - left_average;
        if (difference < best_difference) {
            best_difference = difference;
            best_index = index;
        }
    }
    return static_cast<std::int64_t>(best_index);
}
