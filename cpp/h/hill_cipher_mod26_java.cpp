#include <cstddef>
#include <cstdint>

extern "C" std::int64_t hill_cipher_mod26_java(const std::int64_t *input, std::size_t length,
                                                 std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length < 1 || length > 257 || (input[0] != 0 && input[0] != 1)) return -1;
    const std::int64_t encrypt_key[4] = {3, 3, 2, 5};
    const std::int64_t decrypt_key[4] = {15, 17, 20, 9};
    const auto *key = input[0] == 0 ? encrypt_key : decrypt_key;
    std::uint8_t text[256]; std::size_t text_length = 0;
    for (std::size_t i = 1; i < length; ++i) {
        if (input[i] < 0 || input[i] > 127) return -1;
        auto c = input[i];
        if (c >= 'a' && c <= 'z') c -= 'a' - 'A';
        if (c >= 'A' && c <= 'Z') text[text_length++] = static_cast<std::uint8_t>(c);
    }
    if (text_length & 1) text[text_length++] = 'X';
    if (text_length > capacity || (text_length > 0 && !output)) return -2;
    for (std::size_t i = 0; i < text_length; i += 2) {
        const auto a = text[i] - 'A', b = text[i + 1] - 'A';
        output[i] = static_cast<std::uint8_t>('A' + (key[0] * a + key[1] * b) % 26);
        output[i + 1] = static_cast<std::uint8_t>('A' + (key[2] * a + key[3] * b) % 26);
    }
    return static_cast<std::int64_t>(text_length);
}
