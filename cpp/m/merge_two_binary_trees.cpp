/* Merge two heap-indexed trees and encode the result as little-endian i32 slots. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_tree_slots = 255;
constexpr std::size_t max_input_length = 512;
constexpr std::int64_t null_slot = -1000001;

bool valid_tree(const std::int64_t *input, std::size_t start, std::size_t count) noexcept {
    for (std::size_t index = 0; index < count; ++index) {
        const auto value = input[start + index];
        if (value != null_slot && (value < -100000 || value > 100000)) return false;
        if (index > 0 && input[start + (index - 1) / 2] == null_slot && value != null_slot) return false;
    }
    return true;
}
}

extern "C" std::int64_t merge_two_binary_trees(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length < 2 || length > max_input_length || input == nullptr) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_tree_slots)) return -1;
    const auto first_count = static_cast<std::size_t>(input[0]);
    const auto second_count_position = first_count + 1;
    if (second_count_position >= length) return -1;
    if (input[second_count_position] < 0
            || input[second_count_position] > static_cast<std::int64_t>(max_tree_slots)) return -1;
    const auto second_count = static_cast<std::size_t>(input[second_count_position]);
    constexpr std::size_t first_start = 1;
    const auto second_start = second_count_position + 1;
    if (length != second_start + second_count) return -1;
    if (!valid_tree(input, first_start, first_count) || !valid_tree(input, second_start, second_count)) return -1;

    const auto maximum_slots = first_count > second_count ? first_count : second_count;
    std::int32_t merged[max_tree_slots];
    std::size_t node_count = 0;
    for (std::size_t index = 0; index < maximum_slots; ++index) {
        const auto first = index < first_count ? input[first_start + index] : null_slot;
        const auto second = index < second_count ? input[second_start + index] : null_slot;
        if (first == null_slot && second == null_slot) {
            merged[index] = -1000001;
        } else {
            merged[index] = static_cast<std::int32_t>((first == null_slot ? 0 : first)
                                                      + (second == null_slot ? 0 : second));
            ++node_count;
        }
    }
    auto output_slots = maximum_slots;
    while (output_slots > 0 && merged[output_slots - 1] == -1000001) --output_slots;
    const auto output_bytes = output_slots * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < output_slots; ++index) {
        const auto bits = static_cast<std::uint32_t>(merged[index]);
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[index * 4 + byte] = static_cast<std::uint8_t>((bits >> (byte * 8)) & 255U);
    }
    return static_cast<std::int64_t>(node_count);
}
