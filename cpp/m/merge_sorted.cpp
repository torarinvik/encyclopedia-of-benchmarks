#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_array_length = 64;
constexpr std::size_t max_input_length = 2 + 2 * max_array_length;
constexpr std::size_t max_parseable_input_length = max_input_length + 1;
constexpr std::int64_t min_value = -1'000'000;
constexpr std::int64_t max_value = 1'000'000;
constexpr std::int64_t checksum_offset = 1'000'001;
}

extern "C" std::int64_t merge_sorted(const std::int64_t *values,
                                     std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > max_parseable_input_length) return -1;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_array_length) ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(max_array_length)) return -1;

    const auto left_count = static_cast<std::size_t>(values[0]);
    const auto right_count = static_cast<std::size_t>(values[1]);
    if (length != 2 + left_count + right_count) return -1;
    const std::size_t right_start = 2 + left_count;
    for (std::size_t index = 0; index < left_count; ++index) {
        const auto value = values[2 + index];
        if (value < min_value || value > max_value ||
            (index > 0 && values[2 + index - 1] > value)) return -1;
    }
    for (std::size_t index = 0; index < right_count; ++index) {
        const auto value = values[right_start + index];
        if (value < min_value || value > max_value ||
            (index > 0 && values[right_start + index - 1] > value)) return -1;
    }

    std::size_t left_index = 0, right_index = 0, output_index = 0;
    std::int64_t checksum = 0;
    while (left_index < left_count && right_index < right_count) {
        std::int64_t value;
        if (values[2 + left_index] <= values[right_start + right_index])
            value = values[2 + left_index++];
        else
            value = values[right_start + right_index++];
        checksum += static_cast<std::int64_t>(output_index + 1) * (value + checksum_offset);
        ++output_index;
    }
    while (left_index < left_count) {
        const auto value = values[2 + left_index++];
        checksum += static_cast<std::int64_t>(output_index + 1) * (value + checksum_offset);
        ++output_index;
    }
    while (right_index < right_count) {
        const auto value = values[right_start + right_index++];
        checksum += static_cast<std::int64_t>(output_index + 1) * (value + checksum_offset);
        ++output_index;
    }
    return checksum;
}
