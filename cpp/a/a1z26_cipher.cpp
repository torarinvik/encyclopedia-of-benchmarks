/* Encode ASCII letters as their one-based alphabet positions. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t a1z26_cipher(const std::int64_t *input, std::size_t length,
                                     std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length > 66) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (!((input[index] >= 65 && input[index] <= 90) ||
              (input[index] >= 97 && input[index] <= 122))) return -1;
    if (output_capacity < length) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = input[index];
        output[index] = static_cast<std::uint8_t>(value >= 97 ? value - 96 : value - 64);
    }
    return static_cast<std::int64_t>(length);
}
