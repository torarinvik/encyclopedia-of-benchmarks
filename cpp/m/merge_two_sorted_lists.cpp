// Linear merge over two packed ascending i32 sequences.
#include <cstddef>
#include <cstdint>
#include <limits>

namespace { constexpr std::size_t max_total_length = 1024; }

extern "C" std::int64_t merge_two_sorted_lists(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_total_length + 2) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_total_length) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_total_length)) return -1;
    const auto first_count = static_cast<std::size_t>(input[0]);
    const auto second_count = static_cast<std::size_t>(input[1]);
    if (first_count + second_count > max_total_length ||
        length != first_count + second_count + 2) return -1;
    for (std::size_t index = 0; index < first_count; ++index) {
        const auto value = input[index + 2];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max() ||
            (index != 0 && input[index + 1] > value)) return -1;
    }
    const auto second_start = first_count + 2;
    for (std::size_t index = 0; index < second_count; ++index) {
        const auto value = input[second_start + index];
        if (value < std::numeric_limits<std::int32_t>::min() ||
            value > std::numeric_limits<std::int32_t>::max() ||
            (index != 0 && input[second_start + index - 1] > value)) return -1;
    }

    const auto total_count = first_count + second_count;
    const auto output_bytes = total_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    std::size_t first_index = 0, second_index = 0;
    for (std::size_t written = 0; written < total_count; ++written) {
        std::int64_t value;
        if (first_index == first_count) value = input[second_start + second_index++];
        else if (second_index == second_count) value = input[first_index++ + 2];
        else if (input[first_index + 2] <= input[second_start + second_index])
            value = input[first_index++ + 2];
        else value = input[second_start + second_index++];
        const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[written * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(total_count);
}
