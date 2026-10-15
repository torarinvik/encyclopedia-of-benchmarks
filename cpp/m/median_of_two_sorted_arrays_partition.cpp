// Return twice the exact median using a binary partition of the shorter array.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_array_length = 1000;
constexpr std::int64_t value_min = -1'000'000;
constexpr std::int64_t value_max = 1'000'000;
constexpr std::int64_t partition_min = -1'000'001;
constexpr std::int64_t partition_max = 1'000'001;
}

extern "C" std::int64_t median_of_two_sorted_arrays_partition(
    const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 2 * max_array_length + 2) return -2000001;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_array_length) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_array_length)) return -2000001;

    const auto first_count = static_cast<std::size_t>(input[0]);
    const auto second_count = static_cast<std::size_t>(input[1]);
    const auto total_count = first_count + second_count;
    if (total_count == 0 || total_count > 2 * max_array_length || length != total_count + 2) return -2000001;

    const std::int64_t *first = input + 2;
    const std::int64_t *second = first + first_count;
    for (std::size_t index = 0; index < first_count; ++index) {
        const auto value = input[index + 2];
        if (value < value_min || value > value_max ||
            (index > 0 && input[index + 1] > value)) return -2000001;
    }
    for (std::size_t index = 0; index < second_count; ++index) {
        const auto value = second[index];
        if (value < value_min || value > value_max ||
            (index > 0 && second[index - 1] > value)) return -2000001;
    }

    std::size_t short_count = first_count;
    std::size_t long_count = second_count;
    if (short_count > long_count) {
        const auto *temporary_values = first;
        first = second;
        second = temporary_values;
        short_count = second_count;
        long_count = first_count;
    }

    std::size_t low = 0, high = short_count;
    const std::size_t left_count = (total_count + 1) / 2;
    while (low <= high) {
        const auto first_cut = low + (high - low) / 2;
        const auto second_cut = left_count - first_cut;
        const auto first_left = first_cut == 0 ? partition_min : first[first_cut - 1];
        const auto first_right = first_cut == short_count ? partition_max : first[first_cut];
        const auto second_left = second_cut == 0 ? partition_min : second[second_cut - 1];
        const auto second_right = second_cut == long_count ? partition_max : second[second_cut];

        if (first_left <= second_right && second_left <= first_right) {
            const auto left_max = first_left > second_left ? first_left : second_left;
            if (total_count % 2 != 0) return left_max * 2;
            const auto right_min = first_right < second_right ? first_right : second_right;
            return left_max + right_min;
        }
        if (first_left > second_right) {
            if (first_cut == 0) return -2000001;
            high = first_cut - 1;
        } else {
            low = first_cut + 1;
        }
    }
    return -2000001;
}
