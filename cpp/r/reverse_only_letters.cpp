/* Reverse ASCII letters while leaving every other printable byte in place. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 4096;
bool is_ascii_letter(std::uint8_t value) noexcept {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}
}

extern "C" std::int64_t reverse_only_letters(const std::int64_t *input,
        std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 32 || input[index] > 126) return -1;
    if (output_capacity < length || (length != 0 && output == nullptr)) return -2;
    for (std::size_t index = 0; index < length; ++index) output[index] = static_cast<std::uint8_t>(input[index]);

    std::size_t left = 0, right = length;
    while (left < right) {
        if (!is_ascii_letter(output[left])) {
            ++left;
        } else if (!is_ascii_letter(output[right - 1])) {
            --right;
        } else {
            const auto temporary = output[left];
            output[left] = output[right - 1];
            output[right - 1] = temporary;
            ++left;
            --right;
        }
    }
    return static_cast<std::int64_t>(length);
}
