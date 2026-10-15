// Preserve the pinned Python source's plaintext-minus-repeating-key transform.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t MaxBeaufortLength = 1024; }

extern "C" std::int64_t beaufort_cipher(const std::int64_t *input, std::size_t length,
                                         std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > 2051) return -1;
    const auto mode = input[0], text_value = input[1], key_value = input[2];
    if ((mode != 0 && mode != 1) || text_value < 0 || text_value > MaxBeaufortLength ||
        key_value < 0 || key_value > MaxBeaufortLength) return -1;
    const auto text_length = static_cast<std::size_t>(text_value);
    const auto key_length = static_cast<std::size_t>(key_value);
    if (length != 3 + text_length + key_length || (text_length == 0 && key_length != 0) ||
        (text_length != 0 && (key_length == 0 || key_length > text_length))) return -1;
    const auto key_start = 3 + text_length;
    for (std::size_t i = 0; i < text_length; ++i)
        if (input[3 + i] != ' ' && (input[3 + i] < 'A' || input[3 + i] > 'Z')) return -1;
    for (std::size_t i = 0; i < key_length; ++i)
        if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
    if (output_capacity < text_length || (text_length != 0 && output == nullptr)) return -2;
    std::size_t key_index = 0;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[3 + i];
        if (value == ' ') { output[i] = ' '; continue; }
        const auto text_letter = value - 'A';
        const auto key_letter = input[key_start + key_index % key_length] - 'A';
        const auto mapped = mode == 0 ? (text_letter - key_letter + 26) % 26
                                      : (text_letter + key_letter) % 26;
        output[i] = static_cast<std::uint8_t>('A' + mapped);
        ++key_index;
    }
    return static_cast<std::int64_t>(text_length);
}
