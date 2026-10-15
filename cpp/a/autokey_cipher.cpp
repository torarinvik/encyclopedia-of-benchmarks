/* Plaintext-autokey cipher with a selectable output case dialect. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxAutokeyLength = 1024;
std::int64_t uppercase_letter(std::int64_t value) noexcept {
    return value >= 'a' && value <= 'z' ? value - 32 : value;
}
}

extern "C" std::int64_t autokey_cipher(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 6 || length > 4 + 2 * MaxAutokeyLength) return -1;
    const auto mode = input[0], dialect = input[1];
    const auto text_length_value = input[2], key_length_value = input[3];
    if ((mode != 0 && mode != 1) || (dialect != 0 && dialect != 1)
        || text_length_value < 1 || text_length_value > MaxAutokeyLength
        || key_length_value < 1 || key_length_value > MaxAutokeyLength) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto key_length = static_cast<std::size_t>(key_length_value);
    if (length != 4 + text_length + key_length) return -1;
    const auto key_start = 4 + text_length;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto value = input[4 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
        if (dialect == 1 && mode == 1 && value >= 'A' && value <= 'Z') return -1;
    }
    for (std::size_t i = 0; i < key_length; ++i) {
        const auto value = input[key_start + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
    }
    if (output_capacity < text_length || output == nullptr) return -2;
    for (std::size_t i = 0; i < text_length; ++i) {
        const auto plain = uppercase_letter(input[4 + i]) - 'A';
        const auto key_value = i < key_length ? uppercase_letter(input[key_start + i])
            : mode == 0 ? uppercase_letter(input[4 + i - key_length]) : uppercase_letter(output[i - key_length]);
        const auto shift = key_value - 'A';
        const auto mapped = mode == 0 ? (plain + shift) % 26 : (plain - shift + 26) % 26;
        const auto result = 'A' + mapped + (dialect == 1 ? 32 : 0);
        output[i] = static_cast<std::uint8_t>(result);
    }
    return static_cast<std::int64_t>(text_length);
}
