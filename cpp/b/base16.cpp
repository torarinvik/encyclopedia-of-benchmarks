/* Encode bytes as uppercase Base16 or decode uppercase Base16 bytes. */
#include <cstddef>
#include <cstdint>
static std::int64_t nibble(std::int64_t byte) {
    if (byte >= '0' && byte <= '9') return byte - '0';
    if (byte >= 'A' && byte <= 'F') return byte - 'A' + 10;
    return -1;
}
extern "C" std::int64_t base16(const std::int64_t *input, std::size_t length,
                                std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > 65) return -1;
    const std::int64_t mode = input[0];
    if (mode == 0) {
        const std::size_t count = length - 1, output_length = count * 2;
        for (std::size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
        if (output_capacity < output_length) return -2;
        for (std::size_t i = 0; i < count; ++i) {
            const auto byte = input[i + 1]; const auto high = byte / 16, low = byte % 16;
            output[2 * i] = static_cast<std::uint8_t>(high < 10 ? '0' + high : 'A' + high - 10);
            output[2 * i + 1] = static_cast<std::uint8_t>(low < 10 ? '0' + low : 'A' + low - 10);
        }
        return static_cast<std::int64_t>(output_length);
    }
    if (mode == 1) {
        const std::size_t encoded_length = length - 1;
        if (encoded_length % 2 != 0) return -1;
        for (std::size_t i = 1; i < length; ++i) if (nibble(input[i]) < 0) return -1;
        const std::size_t output_length = encoded_length / 2;
        if (output_capacity < output_length) return -2;
        for (std::size_t i = 0; i < output_length; ++i)
            output[i] = static_cast<std::uint8_t>(nibble(input[1 + 2 * i]) * 16 + nibble(input[2 + 2 * i]));
        return static_cast<std::int64_t>(output_length);
    }
    return -1;
}
