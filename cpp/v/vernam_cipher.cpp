/* Alphabetic Vernam cipher with a repeating key and modulo-26 arithmetic. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxVernamLength = 1024;
}

extern "C" std::int64_t vernam_cipher(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3 || length > 3 + 2 * MaxVernamLength) return -1;
    const auto mode = input[0];
    const auto text_length_value = input[1];
    const auto key_length_value = input[2];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > MaxVernamLength
        || key_length_value < 1 || key_length_value > MaxVernamLength) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto key_length = static_cast<std::size_t>(key_length_value);
    if (length != 3 + text_length + key_length) return -1;
    const auto key_start = 3 + text_length;
    for (std::size_t i = 0; i < text_length; ++i)
        if (input[3 + i] < 'A' || input[3 + i] > 'Z') return -1;
    for (std::size_t i = 0; i < key_length; ++i)
        if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
    if (output_capacity < text_length) return -2;

    for (std::size_t i = 0; i < text_length; ++i) {
        const auto text_value = input[3 + i] - 'A';
        const auto key_value = input[key_start + i % key_length] - 'A';
        const auto mapped = mode == 0 ? (text_value + key_value) % 26
                                      : (text_value - key_value + 26) % 26;
        output[i] = static_cast<std::uint8_t>('A' + mapped);
    }
    return static_cast<std::int64_t>(text_length);
}
