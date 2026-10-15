// Reciprocal Porta tableau cipher.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MaxText = 1024, MaxKey = 64; }

extern "C" std::int64_t porta_cipher(const std::int64_t *input, std::size_t length,
                                     std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > 1091) return -1;
    const auto mode = input[0], text_value = input[1], key_value = input[2];
    if ((mode != 0 && mode != 1) || text_value < 0 || text_value > MaxText || key_value < 0 || key_value > MaxKey) return -1;
    const auto text_length = static_cast<std::size_t>(text_value), key_length = static_cast<std::size_t>(key_value);
    if (length != 3 + text_length + key_length || (text_length != 0 && key_length == 0)) return -1;
    const auto key_start = 3 + text_length;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[3 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
    }
    for (std::size_t i = 0; i < key_length; ++i) {
        const auto value = input[key_start + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
    }
    if (output_capacity < text_length || (text_length != 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < text_length; ++i) {
        auto letter = input[3 + i]; auto key_letter = input[key_start + i % key_length];
        if (letter >= 'a') letter -= 32;
        if (key_letter >= 'a') key_letter -= 32;
        const auto letter_index = letter - 'A'; const auto group = (key_letter - 'A') / 2;
        const auto mapped = letter_index < 13 ? 13 + (letter_index + 13 - group) % 13
                                              : (letter_index - 13 + group) % 13;
        output[i] = static_cast<std::uint8_t>('A' + mapped);
    }
    return static_cast<std::int64_t>(text_length);
}
