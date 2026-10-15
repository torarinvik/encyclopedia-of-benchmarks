/* Encrypt ASCII text with a repeating, case-insensitive Vigenere key. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t vigenere_cipher(const std::int64_t *input, std::size_t length,
                                        std::uint8_t *output,
                                        std::size_t output_capacity) noexcept {
    if (length < 2 || length > 66) return -1;
    std::size_t separator = 0;
    while (separator < length && input[separator] != 0) ++separator;
    if (separator == length || separator + 1 == length) return -1;
    const std::size_t key_length = length - separator - 1;
    for (std::size_t index = 0; index < separator; ++index)
        if (input[index] < 1 || input[index] > 127) return -1;
    for (std::size_t index = 0; index < key_length; ++index) {
        const std::int64_t value = input[separator + 1 + index];
        if (!((value >= 65 && value <= 90) || (value >= 97 && value <= 122))) return -1;
    }
    if (output_capacity < separator) return -2;

    std::size_t key_index = 0;
    for (std::size_t index = 0; index < separator; ++index) {
        const std::int64_t value = input[index];
        std::int64_t mapped = value;
        if (value >= 65 && value <= 90) {
            std::int64_t key_value = input[separator + 1 + key_index];
            if (key_value >= 97) key_value -= 32;
            mapped = 65 + (value - 65 + key_value - 65) % 26;
            key_index = (key_index + 1) % key_length;
        } else if (value >= 97 && value <= 122) {
            std::int64_t key_value = input[separator + 1 + key_index];
            if (key_value <= 90) key_value += 32;
            mapped = 97 + (value - 97 + key_value - 97) % 26;
            key_index = (key_index + 1) % key_length;
        }
        output[index] = static_cast<std::uint8_t>(mapped);
    }
    return static_cast<std::int64_t>(separator);
}
