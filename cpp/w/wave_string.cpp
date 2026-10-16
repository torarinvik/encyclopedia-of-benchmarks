#include <cstddef>
#include <cstdint>

namespace {
bool is_ascii_letter(std::int64_t value) {
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}
}

extern "C" std::int64_t wave_string(const std::int64_t *values, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) {
    constexpr std::size_t max_text_length = 512;
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > max_text_length ||
        length != 1 + static_cast<std::size_t>(values[0])) return -1;
    const std::size_t text_length = static_cast<std::size_t>(values[0]);
    std::size_t letter_count = 0;
    for (std::size_t index = 0; index < text_length; ++index) {
        const std::int64_t byte = values[index + 1];
        if (byte < 32 || byte > 126) return -1;
        if (is_ascii_letter(byte)) ++letter_count;
    }
    const std::size_t output_length = letter_count * (text_length + 2);
    if (output_length > output_capacity || (output_length > 0 && output == nullptr)) return -2;

    std::size_t written = 0;
    for (std::size_t position = 0; position < text_length; ++position) {
        if (!is_ascii_letter(values[position + 1])) continue;
        output[written++] = static_cast<std::uint8_t>(text_length & 255);
        output[written++] = static_cast<std::uint8_t>(text_length >> 8);
        for (std::size_t index = 0; index < text_length; ++index) {
            std::int64_t byte = values[index + 1];
            if (index == position && byte >= 'a' && byte <= 'z') byte -= 32;
            output[written++] = static_cast<std::uint8_t>(byte);
        }
    }
    return static_cast<std::int64_t>(letter_count);
}
