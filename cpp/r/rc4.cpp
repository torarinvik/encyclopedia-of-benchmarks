#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_key_length = 256;
constexpr std::size_t max_plaintext_length = 256;
constexpr std::size_t max_input_values = 515;
}

extern "C" std::int64_t rc4(const std::int64_t *input, std::size_t length,
                              std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_values) return -1;
    const auto key_length_value = input[0];
    const auto plaintext_length_value = input[1];
    if (key_length_value < 1 || key_length_value > static_cast<std::int64_t>(max_key_length) ||
        plaintext_length_value < 0 || plaintext_length_value > static_cast<std::int64_t>(max_plaintext_length)) return -1;
    const auto key_length = static_cast<std::size_t>(key_length_value);
    const auto plaintext_length = static_cast<std::size_t>(plaintext_length_value);
    if (length != 2 + key_length + plaintext_length) return -1;
    for (std::size_t index = 0; index < key_length + plaintext_length; ++index) {
        const auto byte = input[2 + index];
        if (byte < 0 || byte > 255) return -1;
    }
    if (plaintext_length == 0) return 0;
    if (output == nullptr || capacity < plaintext_length) return -2;

    std::uint8_t state[256];
    for (std::size_t index = 0; index < 256; ++index) state[index] = static_cast<std::uint8_t>(index);
    std::size_t j = 0;
    for (std::size_t index = 0; index < 256; ++index) {
        j = (j + state[index] + static_cast<std::size_t>(input[2 + index % key_length])) & 255;
        const auto temporary = state[index];
        state[index] = state[j];
        state[j] = temporary;
    }

    std::size_t i = 0;
    j = 0;
    for (std::size_t offset = 0; offset < plaintext_length; ++offset) {
        i = (i + 1) & 255;
        j = (j + state[i]) & 255;
        const auto temporary = state[i];
        state[i] = state[j];
        state[j] = temporary;
        const auto stream_index = (state[i] + state[j]) & 255;
        const auto plaintext = static_cast<std::uint8_t>(input[2 + key_length + offset]);
        output[offset] = plaintext ^ state[stream_index];
    }
    return static_cast<std::int64_t>(plaintext_length);
}
