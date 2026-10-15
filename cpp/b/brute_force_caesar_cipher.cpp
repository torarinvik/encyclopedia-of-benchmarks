#include <cstddef>
#include <cstdint>

extern "C" std::int64_t brute_force_caesar_cipher(const std::int64_t *input, std::size_t length,
                                                    std::uint8_t *output, std::size_t capacity) noexcept
{
    constexpr std::size_t MAX_MESSAGE_LENGTH = 64;
    constexpr std::size_t KEY_COUNT = 26;
    if (length > MAX_MESSAGE_LENGTH || (length > 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < 0 || input[i] > 127) return -1;
    const std::size_t needed = length * KEY_COUNT + (KEY_COUNT - 1);
    if (output == nullptr || capacity < needed) return -2;
    std::size_t position = 0;
    for (std::size_t key = 0; key < KEY_COUNT; ++key) {
        for (std::size_t i = 0; i < length; ++i) {
            auto value = input[i];
            if (value >= 'A' && value <= 'Z') value = 'A' + (value - 'A' + 26 - static_cast<std::int64_t>(key)) % 26;
            output[position++] = static_cast<std::uint8_t>(value);
        }
        if (key + 1 < KEY_COUNT) output[position++] = static_cast<std::uint8_t>('\n');
    }
    return static_cast<std::int64_t>(KEY_COUNT);
}
