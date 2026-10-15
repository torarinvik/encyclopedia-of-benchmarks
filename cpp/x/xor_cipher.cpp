/* XOR each input byte with a repeating key byte sequence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t xor_cipher(const std::int64_t *input, std::size_t length,
                                   std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length < 3 || length > 66 || input[0] < 0 || input[0] > 63 ||
        input[1] < 1 || input[1] > 63) return -1;
    const std::size_t text_length = static_cast<std::size_t>(input[0]);
    const std::size_t key_length = static_cast<std::size_t>(input[1]);
    if (length != 2 + text_length + key_length) return -1;
    for (std::size_t index = 0; index < text_length + key_length; ++index)
        if (input[2 + index] < 0 || input[2 + index] > 255) return -1;
    if (output_capacity < text_length) return -2;
    for (std::size_t index = 0; index < text_length; ++index)
        output[index] = static_cast<std::uint8_t>(input[2 + index] ^ input[2 + text_length + index % key_length]);
    return static_cast<std::int64_t>(text_length);
}
