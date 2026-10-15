// Merge two ascending i32 arrays and return twice their exact median.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace { constexpr std::size_t max_total_length = 1024; }

extern "C" std::int64_t median_of_two_sorted_arrays(const std::int64_t *input,
    std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_total_length + 2) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_total_length) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_total_length)) return -1;
    const auto first_count = static_cast<std::size_t>(input[0]);
    const auto second_count = static_cast<std::size_t>(input[1]);
    const auto total_count = first_count + second_count;
    if (total_count == 0 || total_count > max_total_length || length != total_count + 2) return -1;
    const auto second_start = first_count + 2;
    for (std::size_t index = 0; index < first_count; ++index) {
        const auto value = input[index + 2];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max() ||
            (index != 0 && input[index + 1] > value)) return -1;
    }
    for (std::size_t index = 0; index < second_count; ++index) {
        const auto value = input[second_start + index];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max() ||
            (index != 0 && input[second_start + index - 1] > value)) return -1;
    }

    std::int32_t merged[max_total_length];
    std::size_t first_index = 0, second_index = 0, written = 0;
    while (first_index < first_count && second_index < second_count) {
        if (input[first_index + 2] <= input[second_start + second_index])
            merged[written++] = static_cast<std::int32_t>(input[first_index++ + 2]);
        else
            merged[written++] = static_cast<std::int32_t>(input[second_start + second_index++]);
    }
    while (first_index < first_count)
        merged[written++] = static_cast<std::int32_t>(input[first_index++ + 2]);
    while (second_index < second_count)
        merged[written++] = static_cast<std::int32_t>(input[second_start + second_index++]);

    if (total_count % 2 != 0) return static_cast<std::int64_t>(merged[total_count / 2]) * 2;
    return static_cast<std::int64_t>(merged[total_count / 2 - 1]) + merged[total_count / 2];
}
