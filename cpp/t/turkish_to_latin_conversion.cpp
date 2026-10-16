#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text_bytes = 1024;

bool continuation(std::uint8_t byte) { return byte >= 0x80 && byte <= 0xBF; }

bool decode_utf8(const std::uint8_t *bytes, std::size_t length, std::size_t index,
                 std::uint32_t &codepoint, std::size_t &width) {
    const std::uint8_t first = bytes[index];
    if (first <= 0x7F) { codepoint = first; width = 1; return true; }
    if (first >= 0xC2 && first <= 0xDF) {
        if (index + 1 >= length || !continuation(bytes[index + 1])) return false;
        codepoint = (std::uint32_t(first & 0x1F) << 6) | (bytes[index + 1] & 0x3F);
        width = 2;
        return true;
    }
    if (first >= 0xE0 && first <= 0xEF) {
        if (index + 2 >= length) return false;
        const auto second = bytes[index + 1], third = bytes[index + 2];
        if (!continuation(second) || !continuation(third) ||
            (first == 0xE0 && second < 0xA0) || (first == 0xED && second >= 0xA0)) return false;
        codepoint = (std::uint32_t(first & 0x0F) << 12) |
                    (std::uint32_t(second & 0x3F) << 6) | (third & 0x3F);
        width = 3;
        return true;
    }
    if (first >= 0xF0 && first <= 0xF4) {
        if (index + 3 >= length) return false;
        const auto second = bytes[index + 1], third = bytes[index + 2], fourth = bytes[index + 3];
        if (!continuation(second) || !continuation(third) || !continuation(fourth) ||
            (first == 0xF0 && second < 0x90) || (first == 0xF4 && second > 0x8F)) return false;
        codepoint = (std::uint32_t(first & 0x07) << 18) |
                    (std::uint32_t(second & 0x3F) << 12) |
                    (std::uint32_t(third & 0x3F) << 6) | (fourth & 0x3F);
        width = 4;
        return true;
    }
    return false;
}

std::uint8_t map_turkish(std::uint32_t codepoint) {
    switch (codepoint) {
        case 0x0131: return 'i'; case 0x0130: return 'I';
        case 0x00FC: return 'u'; case 0x00DC: return 'U';
        case 0x00F6: return 'o'; case 0x00D6: return 'O';
        case 0x015F: return 's'; case 0x015E: return 'S';
        case 0x00E7: return 'c'; case 0x00C7: return 'C';
        case 0x011F: return 'g'; case 0x011E: return 'G';
        default: return 0;
    }
}
}

extern "C" std::int64_t turkish_to_latin_conversion(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 1 || length > max_text_bytes + 1 ||
        input[0] < 0 || input[0] > static_cast<std::int64_t>(max_text_bytes) ||
        length != static_cast<std::size_t>(input[0]) + 1) return -1;
    const auto text_length = static_cast<std::size_t>(input[0]);
    std::uint8_t bytes[max_text_bytes];
    for (std::size_t index = 0; index < text_length; ++index) {
        if (input[index + 1] < 0 || input[index + 1] > 255) return -1;
        bytes[index] = static_cast<std::uint8_t>(input[index + 1]);
    }
    std::size_t result_length = 0;
    for (std::size_t index = 0; index < text_length;) {
        std::uint32_t codepoint;
        std::size_t width;
        if (!decode_utf8(bytes, text_length, index, codepoint, width)) return -1;
        result_length += map_turkish(codepoint) ? 1 : width;
        index += width;
    }
    if (result_length > output_capacity || (result_length > 0 && output == nullptr)) return -2;
    std::size_t written = 0;
    for (std::size_t index = 0; index < text_length;) {
        std::uint32_t codepoint;
        std::size_t width;
        (void)decode_utf8(bytes, text_length, index, codepoint, width);
        const auto mapped = map_turkish(codepoint);
        if (mapped) output[written++] = mapped;
        else for (std::size_t byte = 0; byte < width; ++byte) output[written++] = bytes[index + byte];
        index += width;
    }
    return static_cast<std::int64_t>(result_length);
}
