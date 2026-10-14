/* Encode and decode byte arrays with the RFC 4648 Base32 alphabet. */
#include <cstddef>
#include <cstdint>

static std::int64_t base32_value(std::int64_t byte) {
    if (byte >= 'A' && byte <= 'Z') return byte - 'A';
    if (byte >= '2' && byte <= '7') return byte - '2' + 26;
    return -1;
}

extern "C" std::int64_t base32(const std::int64_t *input, std::size_t length,
                               std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > 66) return -1;
    const auto mode = input[0];
    if (mode == 0) {
        const std::size_t count = length - 1;
        for (std::size_t i = 1; i < length; ++i) if (input[i] < 0 || input[i] > 255) return -1;
        const std::size_t output_length = count == 0 ? 0 : ((count + 4) / 5) * 8;
        if ((output == nullptr && output_length != 0) || output_capacity < output_length) return -2;
        std::size_t written = 0;
        for (std::size_t start = 0; start < count; start += 5) {
            const std::size_t bytes = count - start < 5 ? count - start : 5;
            const std::size_t bits = bytes * 8, symbols = (bits + 4) / 5;
            for (std::size_t symbol = 0; symbol < 8; ++symbol) {
                if (symbol >= symbols) { output[written++] = '='; continue; }
                std::uint8_t value = 0;
                for (std::size_t bit = symbol * 5; bit < symbol * 5 + 5; ++bit) {
                    value = static_cast<std::uint8_t>(value << 1);
                    if (bit < bits) {
                        const auto byte = static_cast<std::uint8_t>(input[1 + start + bit / 8]);
                        value = static_cast<std::uint8_t>(value | ((byte >> (7 - bit % 8)) & 1));
                    }
                }
                output[written++] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"[value];
            }
        }
        return static_cast<std::int64_t>(output_length);
    }
    if (mode != 1) return -1;
    const std::size_t encoded_length = length - 1;
    std::size_t content_length = encoded_length;
    for (std::size_t i = 0; i < encoded_length; ++i) if (input[i + 1] == '=') { content_length = i; break; }
    const std::size_t padding = encoded_length - content_length;
    for (std::size_t i = 0; i < content_length; ++i) if (base32_value(input[i + 1]) < 0) return -1;
    for (std::size_t i = content_length; i < encoded_length; ++i) if (input[i + 1] != '=') return -1;
    const std::size_t remainder = content_length % 8;
    std::size_t expected_padding;
    switch (remainder) {
        case 0: expected_padding = 0; break;
        case 2: expected_padding = 6; break;
        case 4: expected_padding = 4; break;
        case 5: expected_padding = 3; break;
        case 7: expected_padding = 1; break;
        default: return -1;
    }
    if (padding != 0 && (encoded_length % 8 != 0 || padding != expected_padding)) return -1;
    if (content_length != 0 && remainder != 0) {
        const auto final_value = static_cast<std::size_t>(base32_value(input[content_length]));
        const std::size_t unused = remainder == 2 ? 2 : remainder == 4 ? 4 : remainder == 5 ? 1 : 3;
        if ((final_value & ((std::size_t{1} << unused) - 1)) != 0) return -1;
    }
    const std::size_t output_length = content_length * 5 / 8;
    if ((output == nullptr && output_length != 0) || output_capacity < output_length) return -2;
    for (std::size_t i = 0; i < output_length; ++i) {
        std::uint8_t byte = 0;
        for (std::size_t bit = i * 8; bit < i * 8 + 8; ++bit) {
            const auto symbol = static_cast<std::size_t>(base32_value(input[1 + bit / 5]));
            byte = static_cast<std::uint8_t>((byte << 1) | ((symbol >> (4 - bit % 5)) & 1));
        }
        output[i] = byte;
    }
    return static_cast<std::int64_t>(output_length);
}
