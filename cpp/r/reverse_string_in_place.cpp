/* Reverse a byte array by swapping inward from both ends. */
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_length = 4096; }

extern "C" std::int64_t reverse_string_in_place(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > UINT8_MAX) return -1;
    if (output_capacity < length || (length != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < length; ++index) output[index] = static_cast<std::uint8_t>(input[index]);
    std::size_t left = 0, right = length;
    while (left < right) {
        --right;
        if (left >= right) break;
        const auto temporary = output[left];
        output[left] = output[right];
        output[right] = temporary;
        ++left;
    }
    return static_cast<std::int64_t>(length);
}
