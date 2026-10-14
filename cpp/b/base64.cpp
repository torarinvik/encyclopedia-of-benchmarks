/* Encode and decode byte arrays with the RFC 4648 Base64 alphabet. */
#include <cstddef>
#include <cstdint>

static std::int64_t base64_value(std::int64_t byte) {
    if (byte >= 'A' && byte <= 'Z') return byte - 'A';
    if (byte >= 'a' && byte <= 'z') return byte - 'a' + 26;
    if (byte >= '0' && byte <= '9') return byte - '0' + 52;
    if (byte == '+') return 62;
    if (byte == '/') return 63;
    return -1;
}

extern "C" std::int64_t base64(const std::int64_t *input, std::size_t length,
                               std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > 66) return -1;
    const auto mode = input[0];
    if (mode == 0) {
        const std::size_t count = length - 1;
        for (std::size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
        const std::size_t output_length = count == 0 ? 0 : ((count + 2) / 3) * 4;
        const std::size_t symbols = (count * 8 + 5) / 6;
        if ((output == nullptr && output_length != 0) || output_capacity < output_length) return -2;
        for (std::size_t i = 0; i < output_length; ++i) {
            if (i >= symbols) { output[i] = '='; continue; }
            std::uint8_t value = 0;
            for (std::size_t bit = i * 6; bit < i * 6 + 6; ++bit) {
                value = static_cast<std::uint8_t>(value << 1);
                if (bit < count * 8) {
                    const auto byte = static_cast<std::uint8_t>(input[1 + bit / 8]);
                    value = static_cast<std::uint8_t>(value | ((byte >> (7 - bit % 8)) & 1));
                }
            }
            output[i] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"[value];
        }
        return static_cast<std::int64_t>(output_length);
    }
    if (mode != 1) return -1;
    const std::size_t encoded_length = length - 1;
    std::size_t content_length = encoded_length;
    for (std::size_t i = 0; i < encoded_length; ++i) if (input[i + 1] == '=') { content_length = i; break; }
    const std::size_t padding = encoded_length - content_length;
    for (std::size_t i = 0; i < content_length; ++i) if (base64_value(input[i + 1]) < 0) return -1;
    for (std::size_t i = content_length; i < encoded_length; ++i) if (input[i + 1] != '=') return -1;
    const std::size_t remainder = content_length % 4;
    std::size_t expected_padding;
    if (remainder == 0) expected_padding = 0;
    else if (remainder == 2) expected_padding = 2;
    else if (remainder == 3) expected_padding = 1;
    else return -1;
    if (padding != 0 && (encoded_length % 4 != 0 || padding != expected_padding)) return -1;
    if (content_length != 0 && remainder != 0) {
        const auto final_value = static_cast<std::size_t>(base64_value(input[content_length]));
        const std::size_t unused = remainder == 2 ? 4 : 2;
        if ((final_value & ((std::size_t{1} << unused) - 1)) != 0) return -1;
    }
    const std::size_t output_length = content_length * 6 / 8;
    if ((output == nullptr && output_length != 0) || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < output_length; ++i) {
        std::uint8_t byte = 0;
        for (std::size_t bit = i * 8; bit < i * 8 + 8; ++bit) {
            const auto symbol = static_cast<std::size_t>(base64_value(input[1 + bit / 6]));
            byte = static_cast<std::uint8_t>((byte << 1) | ((symbol >> (5 - bit % 6)) & 1));
        }
        output[i] = byte;
    }
    return static_cast<std::int64_t>(output_length);
}
