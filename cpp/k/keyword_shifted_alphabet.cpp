#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_keyword_length = 26;
constexpr std::size_t max_message_length = 512;
constexpr std::size_t max_input_length = 3 + max_keyword_length + max_message_length + 1;
}

extern "C" std::int64_t keyword_shifted_alphabet(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    const auto operation = input[0];
    const auto keyword_length_value = input[1];
    const auto message_length_value = input[2];
    if ((operation != 0 && operation != 1) || keyword_length_value < 1 || keyword_length_value > 26 ||
        message_length_value < 1 || message_length_value > static_cast<std::int64_t>(max_message_length)) return -1;
    const auto keyword_length = static_cast<std::size_t>(keyword_length_value);
    const auto message_length = static_cast<std::size_t>(message_length_value);
    if (length != 3 + keyword_length + message_length) return -1;

    std::uint8_t keyword[max_keyword_length];
    bool seen[26] = {};
    for (std::size_t i = 0; i < keyword_length; ++i) {
        const auto value = input[3 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z'))) return -1;
        const auto lower = static_cast<std::uint8_t>(value >= 'A' && value <= 'Z' ? value + 32 : value);
        const auto index = static_cast<std::size_t>(lower - 'a');
        if (seen[index]) return -1;
        seen[index] = true;
        keyword[i] = lower;
    }
    std::uint8_t message[max_message_length];
    for (std::size_t i = 0; i < message_length; ++i) {
        const auto value = input[3 + keyword_length + i];
        if (value < 0 || value > 127) return -1;
        message[i] = static_cast<std::uint8_t>(value);
    }

    std::uint8_t cipher_alphabet[26], encode[26], decode[26];
    std::size_t cipher_length = 0;
    for (std::size_t i = 0; i < keyword_length; ++i) cipher_alphabet[cipher_length++] = keyword[i];
    for (std::uint8_t letter = 'a'; letter <= 'z'; ++letter) {
        const auto index = static_cast<std::size_t>(letter - 'a');
        if (!seen[index]) cipher_alphabet[cipher_length++] = letter;
    }
    for (std::size_t i = 0; i < 26; ++i) {
        encode[i] = cipher_alphabet[i];
        decode[static_cast<std::size_t>(cipher_alphabet[i] - 'a')] = static_cast<std::uint8_t>('a' + i);
    }

    if (output_capacity < message_length || output == nullptr) return -2;
    for (std::size_t i = 0; i < message_length; ++i) {
        const auto value = message[i];
        const bool uppercase = value >= 'A' && value <= 'Z';
        std::size_t index;
        if (uppercase) index = static_cast<std::size_t>(value - 'A');
        else if (value >= 'a' && value <= 'z') index = static_cast<std::size_t>(value - 'a');
        else { output[i] = value; continue; }
        const auto translated = operation == 0 ? encode[index] : decode[index];
        output[i] = uppercase ? static_cast<std::uint8_t>(translated - ('a' - 'A')) : translated;
    }
    return static_cast<std::int64_t>(message_length);
}
