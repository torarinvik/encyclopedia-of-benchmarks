// Square a sorted array and emit the results in ascending order.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_array_length = 10000;
}

extern "C" std::int64_t squares_of_a_sorted_array(const std::int64_t *input, std::size_t length,
                                                   std::uint8_t *output,
                                                   std::size_t output_capacity) noexcept {
    if (length > max_array_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (input[index] < -10000 || input[index] > 10000) return -1;
        if (index != 0 && input[index - 1] > input[index]) return -1;
    }
    const std::size_t output_bytes = length * 8;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == nullptr)) return -2;

    std::size_t left = 0, right = length, destination = length;
    while (destination != 0) {
        --destination;
        const auto left_value = input[left];
        const auto right_value = input[right - 1];
        const auto left_magnitude = left_value < 0 ? -left_value : left_value;
        const auto right_magnitude = right_value < 0 ? -right_value : right_value;
        const auto value = left_magnitude > right_magnitude ? input[left++] : input[--right];
        const auto square = static_cast<std::uint64_t>(value * value);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[destination * 8 + byte] = static_cast<std::uint8_t>(square >> (byte * 8));
    }
    return static_cast<std::int64_t>(length);
}
