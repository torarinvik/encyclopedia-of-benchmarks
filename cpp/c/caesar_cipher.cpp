/* Apply a normalized Caesar shift to ASCII letters in a byte sequence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t caesar_cipher(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length == 0 || length > 66) return -1;
    const std::size_t text_length = length - 1;
    for (std::size_t index = 0; index < text_length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;
    if (output_capacity < text_length) return -2;

    std::int64_t shift = input[text_length] % 26;
    if (shift < 0) shift += 26;
    for (std::size_t index = 0; index < text_length; ++index) {
        const std::int64_t value = input[index];
        std::int64_t mapped = value;
        if (value >= 65 && value <= 90) mapped = 65 + (value - 65 + shift) % 26;
        else if (value >= 97 && value <= 122) mapped = 97 + (value - 97 + shift) % 26;
        output[index] = static_cast<std::uint8_t>(mapped);
    }
    return static_cast<std::int64_t>(text_length);
}
